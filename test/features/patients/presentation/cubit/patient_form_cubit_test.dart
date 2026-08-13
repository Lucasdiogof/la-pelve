import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient.dart';
import 'package:fisioterapia_pelvica/features/patients/domain/entities/patient_enums.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/cubit/patient_form_cubit.dart';
import 'package:fisioterapia_pelvica/features/patients/presentation/widgets/attachment_picker_sheet.dart';

void main() {
  group('PatientFormCubit step visibility', () {
    test('hides gynecological/obstetric steps when gender is male', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );

      expect(cubit.stepCount, 9);
      cubit.close();
    });

    test('shows gynecological/obstetric steps when gender is female', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Maria',
            phone: '11933334444',
            gender: Gender.female,
          ),
        ),
      );

      expect(cubit.stepCount, 11);
      cubit.close();
    });
  });

  group('PatientFormCubit.canProceed', () {
    test('blocks advancing from dados pessoais with an incomplete name', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Ab',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );

      expect(cubit.canProceed, isFalse);
      cubit.close();
    });

    test('blocks advancing from dados pessoais with an invalid phone', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '123',
            gender: Gender.male,
          ),
        ),
      );

      expect(cubit.canProceed, isFalse);
      cubit.close();
    });

    test('blocks advancing from dados pessoais without a gender', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
          ),
        ),
      );

      expect(cubit.canProceed, isFalse);
      cubit.close();
    });

    test('allows advancing once dados pessoais is complete', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );

      expect(cubit.canProceed, isTrue);
      cubit.close();
    });

    test('does not gate steps other than dados pessoais', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );
      cubit.nextStep();

      expect(cubit.currentStep, PatientFormStep.medicalHistory);
      expect(cubit.canProceed, isTrue);
      cubit.close();
    });
  });

  group('PatientFormCubit navigation', () {
    test('nextStep does nothing while dados pessoais is incomplete', () {
      final cubit = PatientFormCubit();

      cubit.nextStep();

      expect(cubit.state.stepIndex, 0);
      cubit.close();
    });

    test('nextStep advances once the current step is valid', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );

      cubit.nextStep();

      expect(cubit.state.stepIndex, 1);
      cubit.close();
    });

    test('nextStep does not advance past the last step', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );
      for (var i = 0; i < cubit.stepCount + 3; i++) {
        cubit.nextStep();
      }

      expect(cubit.state.stepIndex, cubit.stepCount - 1);
      expect(cubit.isLastStep, isTrue);
      cubit.close();
    });

    test('previousStep does not go below the first step', () {
      final cubit = PatientFormCubit();

      cubit.previousStep();

      expect(cubit.state.stepIndex, 0);
      cubit.close();
    });

    test('previousStep moves back one step', () {
      final cubit = PatientFormCubit();
      cubit.updatePatient(
        cubit.state.patient.copyWith(
          personalInfo: const PersonalInfo(
            name: 'Joao Silva',
            phone: '11933334444',
            gender: Gender.male,
          ),
        ),
      );
      cubit.nextStep();
      cubit.previousStep();

      expect(cubit.state.stepIndex, 0);
      cubit.close();
    });
  });

  group('PatientFormCubit ficha de avaliação attachments', () {
    PickedAttachmentFile file(String name) => PickedAttachmentFile(
      bytes: Uint8List(0),
      fileName: name,
      contentType: 'image/jpeg',
    );

    test('adds a file to the list', () {
      final cubit = PatientFormCubit();

      cubit.addAssessmentFile(file('foto1.jpg'));

      expect(cubit.state.assessmentFiles.length, 1);
      expect(cubit.state.assessmentFiles.single.fileName, 'foto1.jpg');
      cubit.close();
    });

    test('removes a file by index', () {
      final cubit = PatientFormCubit();
      cubit.addAssessmentFile(file('foto1.jpg'));
      cubit.addAssessmentFile(file('foto2.jpg'));

      cubit.removeAssessmentFile(0);

      expect(cubit.state.assessmentFiles.length, 1);
      expect(cubit.state.assessmentFiles.single.fileName, 'foto2.jpg');
      cubit.close();
    });
  });

  group('PatientFormCubit.isEditing', () {
    test('is false when created without an existing patient', () {
      final cubit = PatientFormCubit();
      expect(cubit.isEditing, isFalse);
      cubit.close();
    });

    test('is true when created with an existing patient', () {
      final existing = Patient(id: 'p1', createdAt: DateTime.utc(2026, 1, 1));
      final cubit = PatientFormCubit(existingPatient: existing);

      expect(cubit.isEditing, isTrue);
      expect(cubit.state.patient, existing);
      cubit.close();
    });
  });
}
