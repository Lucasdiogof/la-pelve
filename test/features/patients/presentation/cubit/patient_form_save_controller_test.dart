import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:la_pelve/core/error/failures.dart';
import 'package:la_pelve/core/error/result.dart';
import 'package:la_pelve/features/patients/domain/entities/attachment.dart';
import 'package:la_pelve/features/patients/domain/entities/patient.dart';
import 'package:la_pelve/features/patients/domain/entities/patient_consent.dart';
import 'package:la_pelve/features/patients/domain/repositories/attachment_repository.dart';
import 'package:la_pelve/features/patients/domain/repositories/patient_consent_repository.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patient_form_save_controller.dart';
import 'package:la_pelve/features/patients/presentation/cubit/patients_cubit.dart';
import 'package:la_pelve/features/patients/presentation/widgets/attachment_picker_sheet.dart';

class _MockPatientsCubit extends Mock implements PatientsCubit {}

class _MockAttachmentRepository extends Mock implements AttachmentRepository {}

class _MockPatientConsentRepository extends Mock
    implements PatientConsentRepository {}

void main() {
  late _MockPatientsCubit patientsCubit;
  late _MockAttachmentRepository attachmentRepository;
  late _MockPatientConsentRepository consentRepository;
  late PatientFormSaveController controller;

  Patient patientWithPhone(String phone) => Patient(
    id: 'p1',
    createdAt: DateTime.utc(2026, 1, 1),
    personalInfo: PersonalInfo(name: 'Joao Silva', phone: phone),
  );

  PatientConsent consentFor(String contactValue) => PatientConsent(
    id: 'c1',
    patientId: 'p1',
    channel: kWhatsappChannel,
    purpose: kAppointmentReminderPurpose,
    contactValue: contactValue,
    grantedAt: DateTime.utc(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(
      Patient(id: 'fallback', createdAt: DateTime.utc(2026, 1, 1)),
    );
    registerFallbackValue(AttachmentCategory.assessmentForm);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    patientsCubit = _MockPatientsCubit();
    attachmentRepository = _MockAttachmentRepository();
    consentRepository = _MockPatientConsentRepository();
    controller = PatientFormSaveController(
      patientsCubit: patientsCubit,
      attachmentRepository: attachmentRepository,
      consentRepository: consentRepository,
    );

    when(
      () => patientsCubit.updatePatient(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => patientsCubit.addPatient(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  group('PatientFormSaveController.save — ordem e atomicidade do consentimento', () {
    test('revoke falha: grant nunca é chamado', () async {
      final cubit = PatientFormCubit(
        existingPatient: patientWithPhone('62999999999'), // A
        existingConsent: consentFor('+5562999999999'), // A
      );
      cubit.setWhatsappConsent(false); // desliga -> revoga A

      when(
        () => consentRepository.revoke('c1'),
      ).thenAnswer((_) async => Error(ServerFailure()));

      final outcome = await controller.save(formCubit: cubit, state: cubit.state);

      verify(() => consentRepository.revoke('c1')).called(1);
      verifyNever(() => consentRepository.grant(
            patientId: any(named: 'patientId'),
            channel: any(named: 'channel'),
            purpose: any(named: 'purpose'),
            contactValue: any(named: 'contactValue'),
            source: any(named: 'source'),
          ));
      expect(outcome, isA<PatientSaveSucceeded>());
      expect((outcome as PatientSaveSucceeded).consentFailed, isTrue);
      await cubit.close();
    });

    test(
      'revoke funciona e grant falha: A permanece revogado, erro é reportado',
      () async {
        final cubit = PatientFormCubit(
          existingPatient: patientWithPhone('62999999999'), // A
          existingConsent: consentFor('+5562999999999'), // A
        );
        setPhone(cubit, '62988888888'); // A -> B
        cubit.setWhatsappConsent(true); // religa manualmente para B

        when(
          () => consentRepository.revoke('c1'),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => consentRepository.grant(
            patientId: any(named: 'patientId'),
            channel: any(named: 'channel'),
            purpose: any(named: 'purpose'),
            contactValue: any(named: 'contactValue'),
            source: any(named: 'source'),
          ),
        ).thenAnswer((_) async => Error(ServerFailure()));

        final outcome = await controller.save(
          formCubit: cubit,
          state: cubit.state,
        );

        verifyInOrder([
          () => consentRepository.revoke('c1'),
          () => consentRepository.grant(
                patientId: any(named: 'patientId'),
                channel: any(named: 'channel'),
                purpose: any(named: 'purpose'),
                contactValue: any(named: 'contactValue'),
                source: any(named: 'source'),
              ),
        ]);
        expect(outcome, isA<PatientSaveSucceeded>());
        expect((outcome as PatientSaveSucceeded).consentFailed, isTrue);
        await cubit.close();
      },
    );

    test(
      'A -> B -> A sem tocar o switch: paciente salva, zero operações de '
      'consentimento',
      () async {
        final cubit = PatientFormCubit(
          existingPatient: patientWithPhone('62999999999'), // A
          existingConsent: consentFor('+5562999999999'), // A
        );
        setPhone(cubit, '62988888888'); // A -> B
        setPhone(cubit, '62999999999'); // B -> A, sem tocar o switch

        final outcome = await controller.save(
          formCubit: cubit,
          state: cubit.state,
        );

        verify(() => patientsCubit.updatePatient(any())).called(1);
        verifyNever(() => consentRepository.revoke(any()));
        verifyNever(() => consentRepository.grant(
              patientId: any(named: 'patientId'),
              channel: any(named: 'channel'),
              purpose: any(named: 'purpose'),
              contactValue: any(named: 'contactValue'),
              source: any(named: 'source'),
            ));
        expect(outcome, isA<PatientSaveSucceeded>());
        expect((outcome as PatientSaveSucceeded).consentFailed, isFalse);
        await cubit.close();
      },
    );

    test(
      'desligado manualmente em A -> B -> A: continua desligado e revoga A '
      'no save',
      () async {
        final cubit = PatientFormCubit(
          existingPatient: patientWithPhone('62999999999'), // A
          existingConsent: consentFor('+5562999999999'), // A
        );
        cubit.setWhatsappConsent(false);
        setPhone(cubit, '62988888888'); // A -> B
        setPhone(cubit, '62999999999'); // B -> A

        when(
          () => consentRepository.revoke('c1'),
        ).thenAnswer((_) async => const Success(null));

        final outcome = await controller.save(
          formCubit: cubit,
          state: cubit.state,
        );

        verify(() => consentRepository.revoke('c1')).called(1);
        verifyNever(() => consentRepository.grant(
              patientId: any(named: 'patientId'),
              channel: any(named: 'channel'),
              purpose: any(named: 'purpose'),
              contactValue: any(named: 'contactValue'),
              source: any(named: 'source'),
            ));
        expect((outcome as PatientSaveSucceeded).consentFailed, isFalse);
        await cubit.close();
      },
    );
  });

  group('PatientFormSaveController.save — double submit', () {
    test(
      'uma segunda chamada enquanto a primeira está em andamento é ignorada',
      () async {
        final cubit = PatientFormCubit(existingPatient: patientWithPhone('62999999999'));

        final patientSaveCompleter = Completer<Result<void>>();
        when(
          () => patientsCubit.updatePatient(any()),
        ).thenAnswer((_) => patientSaveCompleter.future);

        final firstCall = controller.save(formCubit: cubit, state: cubit.state);
        // A segunda chamada chega antes da primeira terminar.
        final secondCall = controller.save(formCubit: cubit, state: cubit.state);

        expect(controller.isSaving, isTrue);
        patientSaveCompleter.complete(const Success(null));

        final results = await Future.wait([firstCall, secondCall]);

        expect(results[1], isNull); // a segunda chamada foi ignorada
        expect(results[0], isA<PatientSaveSucceeded>());
        verify(() => patientsCubit.updatePatient(any())).called(1);
        expect(controller.isSaving, isFalse);
        await cubit.close();
      },
    );
  });

  group('PatientFormSaveController.save — anexos', () {
    test('sobe cada arquivo da ficha de avaliação após salvar o paciente', () async {
      final cubit = PatientFormCubit(existingPatient: patientWithPhone('62999999999'));
      final file = PickedAttachmentFile(
        bytes: Uint8List(0),
        fileName: 'foto.jpg',
        contentType: 'image/jpeg',
      );
      cubit.addAssessmentFile(file);

      when(
        () => attachmentRepository.upload(
          patientId: any(named: 'patientId'),
          category: any(named: 'category'),
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
          contentType: any(named: 'contentType'),
        ),
      ).thenAnswer(
        (_) async => Success(
          Attachment(
            id: 'a1',
            patientId: 'p1',
            storagePath: 'path',
            fileName: 'foto.jpg',
            contentType: 'image/jpeg',
            category: AttachmentCategory.assessmentForm,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ),
      );

      final outcome = await controller.save(formCubit: cubit, state: cubit.state);

      verify(
        () => attachmentRepository.upload(
          patientId: 'p1',
          category: AttachmentCategory.assessmentForm,
          bytes: file.bytes,
          fileName: 'foto.jpg',
          contentType: 'image/jpeg',
        ),
      ).called(1);
      expect(outcome, isA<PatientSaveSucceeded>());
      await cubit.close();
    });
  });

  group('PatientFormSaveController.save — falha ao salvar o paciente', () {
    test('não tenta reconciliar consentimento quando o paciente falha', () async {
      final cubit = PatientFormCubit(existingPatient: patientWithPhone('62999999999'));
      when(
        () => patientsCubit.updatePatient(any()),
      ).thenAnswer((_) async => Error(ServerFailure('boom')));

      final outcome = await controller.save(formCubit: cubit, state: cubit.state);

      expect(outcome, isA<PatientSaveFailed>());
      verifyNever(() => consentRepository.revoke(any()));
      verifyNever(() => consentRepository.grant(
            patientId: any(named: 'patientId'),
            channel: any(named: 'channel'),
            purpose: any(named: 'purpose'),
            contactValue: any(named: 'contactValue'),
            source: any(named: 'source'),
          ));
      await cubit.close();
    });
  });

  group('Formulário cancelado', () {
    test('nenhuma gravação acontece se save() nunca é chamado', () {
      PatientFormCubit(existingPatient: patientWithPhone('62999999999')).close();

      verifyZeroInteractions(patientsCubit);
      verifyZeroInteractions(attachmentRepository);
      verifyZeroInteractions(consentRepository);
    });
  });
}

void setPhone(PatientFormCubit cubit, String phone) {
  cubit.updatePatient(
    cubit.state.patient.copyWith(
      personalInfo: cubit.state.patient.personalInfo.copyWith(phone: phone),
    ),
  );
}
