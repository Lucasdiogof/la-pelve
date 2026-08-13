-- ============================================================================
-- Rename the entire clinical domain model from Portuguese to English.
--
-- IMPORTANT — READ BEFORE RUNNING:
--   1. BACK UP THE DATABASE FIRST (Supabase Dashboard → Database → Backups,
--      or `pg_dump`). This migration is irreversible without a restore.
--   2. This whole script runs inside one transaction (BEGIN/COMMIT at the
--      bottom). If anything fails, Postgres rolls back everything — nothing
--      is left half-renamed.
--   3. Run this in the Supabase SQL editor, or via `psql`/`supabase db push`.
--   4. Deploy the new app build (with the renamed Dart code) at the same
--      time as this migration — the old app build reads the old Portuguese
--      column/key names and will break against the new schema, and vice
--      versa.
--   5. Helper functions used below are dropped at the end; they don't
--      persist in your schema.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- Helpers: translate a single enum value, or every value in a text array,
-- using a {"old": "new"} mapping. Unmapped values pass through unchanged
-- (safety net for values that are already correct or unexpected).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.translate_enum(value text, mapping jsonb)
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(mapping->>value, value);
$$;

CREATE OR REPLACE FUNCTION pg_temp.translate_enum_array(arr jsonb, mapping jsonb)
RETURNS jsonb LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN arr IS NULL THEN NULL
    ELSE COALESCE(
      (SELECT jsonb_agg(pg_temp.translate_enum(value, mapping))
       FROM jsonb_array_elements_text(arr) AS value),
      '[]'::jsonb
    )
  END;
$$;

-- ============================================================================
-- 1. patients — flat columns
-- ============================================================================
ALTER TABLE patients RENAME COLUMN nome TO name;
ALTER TABLE patients RENAME COLUMN idade TO age;
ALTER TABLE patients RENAME COLUMN telefone TO phone;
ALTER TABLE patients RENAME COLUMN profissao TO occupation;
ALTER TABLE patients RENAME COLUMN valor_consulta TO consultation_fee;
ALTER TABLE patients RENAME COLUMN sexo TO gender;

UPDATE patients SET gender = pg_temp.translate_enum(gender, '{
  "feminino": "female",
  "masculino": "male"
}'::jsonb)
WHERE gender IS NOT NULL;

-- ============================================================================
-- 2. patients — jsonb column: anamnese -> medical_history
-- ============================================================================
ALTER TABLE patients RENAME COLUMN anamnese TO medical_history;

UPDATE patients SET medical_history = jsonb_build_object(
  'chiefComplaint', medical_history->'queixaPrincipal',
  'hasMedicalDiagnosis', medical_history->'temDiagnosticoMedico',
  'medicalDiagnosis', medical_history->'diagnosticoMedico',
  'symptomsOnset', medical_history->'inicioSintomas',
  'hadPreviousTreatment', medical_history->'realizouTratamento',
  'treatmentDescription', medical_history->'descricaoTratamento',
  'hasChronicDiseases', medical_history->'doencasCronicas',
  'chronicDiseasesDescription', medical_history->'descricaoDoencasCronicas',
  'takesContinuousMedication', medical_history->'usoContinuoMedicamentos',
  'medicationsDescription', medical_history->'descricaoMedicamentos',
  'smoking', medical_history->'tabagismo',
  'consumesAlcohol', medical_history->'consomeAlcool',
  'practicesPhysicalActivity', medical_history->'praticaAtividadeFisica',
  'imagingExams', medical_history->'examesImagem'
)
WHERE medical_history IS NOT NULL;

-- ============================================================================
-- 3. patients — jsonb column: historico_ginecologico -> gynecological_history
-- ============================================================================
ALTER TABLE patients RENAME COLUMN historico_ginecologico TO gynecological_history;

UPDATE patients SET gynecological_history = jsonb_build_object(
  'ageAtMenarche', gynecological_history->'idadePrimeiraMenstruacao',
  'currentlyMenstruating', gynecological_history->'menstruaAtualmente',
  'regularCycle', gynecological_history->'cicloRegular',
  'contraceptiveMethod', to_jsonb(pg_temp.translate_enum(
    gynecological_history->>'metodoContraceptivo', '{
      "pilula": "pill", "injecao": "injection", "diu": "iud",
      "implanon": "implant", "camisinha": "condom", "nenhum": "none"
    }'::jsonb
  )),
  'menopause', gynecological_history->'menopausa',
  'hormoneReplacementTherapy', gynecological_history->'reposicaoHormonal',
  'hormoneReplacementTherapyDescription', gynecological_history->'descricaoReposicaoHormonal',
  'menstrualFlow', to_jsonb(pg_temp.translate_enum(
    gynecological_history->>'fluxoMenstrual', '{
      "leve": "light", "moderado": "moderate", "intenso": "heavy"
    }'::jsonb
  )),
  'crampsScore0to10', gynecological_history->'colica0a10',
  'isInMenopause', gynecological_history->'estaNaMenopausa',
  'approximateLastMenstruationDate', gynecological_history->'dataUltimaMenstruacaoAproximada',
  'pelvicPainOutsidePeriod', gynecological_history->'dorPelvicaForaPeriodo',
  'bleedingOutsidePeriod', gynecological_history->'sangramentoForaPeriodo',
  'endometriosis', gynecological_history->'endometriose',
  'polycysticOvarySyndrome', gynecological_history->'sindromeOvariosPolicisticos',
  'recurrentUrinaryInfections', gynecological_history->'infeccoesUrinariasRecorrentes',
  'recurrentVaginalInfections', gynecological_history->'infeccoesVaginaisRecorrentes'
)
WHERE gynecological_history IS NOT NULL;

-- ============================================================================
-- 4. patients — jsonb column: historico_obstetrico -> obstetric_history
--    (includes the nested `gestacoes` array -> `pregnancies`)
-- ============================================================================
ALTER TABLE patients RENAME COLUMN historico_obstetrico TO obstetric_history;

UPDATE patients SET obstetric_history = jsonb_build_object(
  'hasBeenPregnant', obstetric_history->'jaEngravidou',
  'pregnancyCount', obstetric_history->'numeroGestacoes',
  'pregnancies', COALESCE(
    (SELECT jsonb_agg(jsonb_build_object(
      'pregnancyLoss', g->'perdaGestacional',
      'lossDescription', g->'descricaoPerda',
      'deliveryMethod', to_jsonb(pg_temp.translate_enum(g->>'viaDeParto', '{
        "normal": "vaginal", "cesarea": "cesarean"
      }'::jsonb)),
      'deliveryComplication', to_jsonb(pg_temp.translate_enum(g->>'complicacaoParto', '{
        "nenhuma": "none", "laceracao": "laceration", "episiotomia": "episiotomy"
      }'::jsonb)),
      'hadComplications', g->'teveComplicacoes',
      'complicationDescription', g->'descricaoComplicacao',
      'approximateBabyWeight', g->'pesoAproximadoBebe',
      'forcepsOrVacuumUse', g->'usoForcepsOuVacuo'
    ))
    FROM jsonb_array_elements(COALESCE(obstetric_history->'gestacoes', '[]'::jsonb)) AS g),
    '[]'::jsonb
  ),
  'currentlyPregnant', obstetric_history->'estaGestanteAtualmente',
  'desiredDeliveryMethod', to_jsonb(pg_temp.translate_enum(
    obstetric_history->>'viaDePartoDesejado', '{
      "normal": "vaginal", "cesarea": "cesarean"
    }'::jsonb
  )),
  'gestationWeeks', obstetric_history->'semanasGestacao',
  'estimatedDeliveryDate', obstetric_history->'dataProvavelParto',
  'highRiskPregnancy', obstetric_history->'gestacaoDeRisco',
  'highRiskPregnancyDescription', obstetric_history->'descricaoGestacaoRisco'
)
WHERE obstetric_history IS NOT NULL;

-- ============================================================================
-- 5. patients — jsonb column: historico_cirurgico -> surgical_history
-- ============================================================================
ALTER TABLE patients RENAME COLUMN historico_cirurgico TO surgical_history;

UPDATE patients SET surgical_history = jsonb_build_object(
  'surgeries', pg_temp.translate_enum_array(surgical_history->'cirurgias', '{
    "histerectomia": "hysterectomy", "laqueadura": "tubalLigation",
    "perineoplastia": "perineoplasty", "sling": "sling",
    "outro": "other", "nenhum": "none"
  }'::jsonb),
  'otherSurgeryDescription', surgical_history->'descricaoOutraCirurgia'
)
WHERE surgical_history IS NOT NULL;

-- ============================================================================
-- 6. patients — jsonb column: funcao_urinaria -> urinary_function
-- ============================================================================
ALTER TABLE patients RENAME COLUMN funcao_urinaria TO urinary_function;

UPDATE patients SET urinary_function = jsonb_build_object(
  'urgency', urinary_function->'urgencia',
  'urgencyDescription', urinary_function->'descricaoUrgencia',
  'stressIncontinence', urinary_function->'incontinenciaEsforco',
  'incontinenceTriggers', pg_temp.translate_enum_array(urinary_function->'gatilhosIncontinencia', '{
    "tosse": "cough", "espirro": "sneeze", "peso": "liftingWeight",
    "agachar": "squatting", "caminhando": "walking",
    "mudandoDePosicao": "changingPosition", "outros": "other"
  }'::jsonb),
  'otherTriggerDescription', urinary_function->'descricaoOutroGatilho',
  'nocturnalEnuresis', urinary_function->'enureseNoturna',
  'enuresisDescription', urinary_function->'descricaoEnurese',
  'hesitancy', urinary_function->'hesitacao',
  'hesitancyDescription', urinary_function->'descricaoHesitacao',
  'urinaryStraining', urinary_function->'esforcoMiccional',
  'urinaryStrainingDescription', urinary_function->'descricaoEsforcoMiccional',
  'postVoidDribbling', urinary_function->'gotejamentoPosMiccional',
  'dribblingDescription', urinary_function->'descricaoGotejamento',
  'incompleteEmptying', urinary_function->'esvaziamentoIncompleto',
  'incompleteEmptyingDescription', urinary_function->'descricaoEsvaziamentoIncompleto',
  'urgencyAssociatedLeakage', urinary_function->'perdaAssociadaUrgencia',
  'leakageAmount', to_jsonb(pg_temp.translate_enum(urinary_function->>'quantidadePerda', '{
    "gotas": "drops", "pequena": "small", "moderada": "moderate", "grande": "large"
  }'::jsonb)),
  'usesPads', urinary_function->'utilizaAbsorvente',
  'padsPerDay', urinary_function->'quantosAbsorventes',
  'painOrBurningWhenUrinating', urinary_function->'dorArdenciaAoUrinar',
  'weakUrinaryStream', urinary_function->'jatoUrinarioFraco'
)
WHERE urinary_function IS NOT NULL;

-- ============================================================================
-- 7. patients — jsonb column: funcao_sexual -> sexual_function
-- ============================================================================
ALTER TABLE patients RENAME COLUMN funcao_sexual TO sexual_function;

UPDATE patients SET sexual_function = jsonb_build_object(
  'sexuallyActive', sexual_function->'vidaSexualAtiva',
  'needsLubricant', sexual_function->'precisaLubrificante',
  'orgasmDifficulty', sexual_function->'dificuldadeOrgasmo',
  'orgasmDifficultyDescription', sexual_function->'descricaoDificuldadeOrgasmo',
  'sexualDesire', to_jsonb(pg_temp.translate_enum(sexual_function->>'desejoSexual', '{
    "preservado": "preserved", "reduzido": "reduced",
    "ausente": "absent", "aumentado": "increased"
  }'::jsonb)),
  'sexualActivityFrequency', sexual_function->'frequenciaAtividadeSexual',
  'painDuringPenetration', sexual_function->'dorNaPenetracao',
  'penetrationPainType', to_jsonb(pg_temp.translate_enum(sexual_function->>'tipoDorPenetracao', '{
    "superficial": "superficial", "profunda": "deep"
  }'::jsonb)),
  'painDuringOrAfterIntercourse', sexual_function->'dorDuranteOuDepoisRelacao',
  'painIntensity0to10', sexual_function->'intensidadeDor0a10',
  'dryness', sexual_function->'ressecamento'
)
WHERE sexual_function IS NOT NULL;

-- ============================================================================
-- 8. patients — jsonb column: funcao_intestinal -> bowel_function
-- ============================================================================
ALTER TABLE patients RENAME COLUMN funcao_intestinal TO bowel_function;

UPDATE patients SET bowel_function = jsonb_build_object(
  'bowelFrequency', to_jsonb(pg_temp.translate_enum(bowel_function->>'frequenciaEvacuatoria', '{
    "umaVezAoDia": "onceDaily", "algumasVezesPorSemana": "afewTimesPerWeek",
    "menosDeTresVezesPorSemana": "fewerThanThreeTimesPerWeek", "personalizado": "custom"
  }'::jsonb)),
  'customFrequencyValue', bowel_function->'frequenciaPersonalizadaValor',
  'usesLaxative', bowel_function->'usaLaxante',
  'laxativeDescription', bowel_function->'descricaoLaxante',
  'strainsToDefecate', bowel_function->'forcaParaEvacuar',
  'painToDefecate', bowel_function->'dorParaEvacuar',
  'incompleteEmptying', bowel_function->'esvaziamentoIncompleto',
  'gasIncontinence', bowel_function->'perdeGases',
  'fecalIncontinence', bowel_function->'perdeFezes',
  'bristolScale', to_jsonb(pg_temp.translate_enum(bowel_function->>'escalaBristol', '{
    "tipo1": "type1", "tipo2": "type2", "tipo3": "type3", "tipo4": "type4",
    "tipo5": "type5", "tipo6": "type6", "tipo7": "type7"
  }'::jsonb)),
  'obstructionSensation', bowel_function->'sensacaoObstrucao',
  'fecalUrgency', bowel_function->'urgenciaFecal',
  'hemorrhoids', bowel_function->'presencaHemorroidas'
)
WHERE bowel_function IS NOT NULL;

-- ============================================================================
-- 9. patients — jsonb column: plano_tratamento -> treatment_plan
-- ============================================================================
ALTER TABLE patients RENAME COLUMN plano_tratamento TO treatment_plan;

UPDATE patients SET treatment_plan = jsonb_build_object(
  'physiotherapyDiagnosis', treatment_plan->'diagnosticoFisioterapeutico',
  'treatmentGoal', treatment_plan->'objetivoTratamento',
  'treatmentApproach', treatment_plan->'condutaTratamento',
  'suggestedFrequency', treatment_plan->'frequenciaSugerida'
)
WHERE treatment_plan IS NOT NULL;

-- ============================================================================
-- 10. patients — jsonb column: encerramento -> discharge (nullable)
-- ============================================================================
ALTER TABLE patients RENAME COLUMN encerramento TO discharge;

UPDATE patients SET discharge = jsonb_build_object(
  'date', discharge->'data',
  'reason', to_jsonb(pg_temp.translate_enum(discharge->>'motivo', '{
    "alta": "completed", "abandono": "dropOut",
    "encaminhamento": "referred", "outro": "other"
  }'::jsonb)),
  'finalNote', discharge->'observacaoFinal'
)
WHERE discharge IS NOT NULL;

-- ============================================================================
-- 11. evolution_entries
-- ============================================================================
ALTER TABLE evolution_entries RENAME COLUMN data TO date;
ALTER TABLE evolution_entries RENAME COLUMN descricao TO description;
ALTER TABLE evolution_entries RENAME COLUMN fisioterapeuta_id TO physiotherapist_id;

-- ============================================================================
-- 12. appointments
-- ============================================================================
ALTER TABLE appointments RENAME COLUMN data TO date;
ALTER TABLE appointments RENAME COLUMN hora TO time;
ALTER TABLE appointments RENAME COLUMN nome_paciente TO patient_name;

UPDATE appointments SET status = pg_temp.translate_enum(status, '{
  "agendado": "scheduled", "confirmado": "confirmed", "atendido": "fulfilled",
  "cancelado": "cancelled", "faltou": "noShow", "reagendado": "rescheduled"
}'::jsonb)
WHERE status IS NOT NULL;

ALTER TABLE appointments ALTER COLUMN status SET DEFAULT 'scheduled';

-- ============================================================================
-- 13. financial_entries
-- ============================================================================
ALTER TABLE financial_entries RENAME COLUMN data TO date;
ALTER TABLE financial_entries RENAME COLUMN valor TO amount;
ALTER TABLE financial_entries RENAME COLUMN observacoes TO notes;
ALTER TABLE financial_entries RENAME COLUMN forma_pagamento TO payment_method;
ALTER TABLE financial_entries RENAME COLUMN forma_pagamento_outra_descricao TO other_payment_method_description;
ALTER TABLE financial_entries RENAME COLUMN status_outra_descricao TO other_status_description;

UPDATE financial_entries SET payment_method = pg_temp.translate_enum(payment_method, '{
  "pix": "pix", "dinheiro": "cash", "cartao": "card",
  "transferencia": "transfer", "outro": "other"
}'::jsonb)
WHERE payment_method IS NOT NULL;

UPDATE financial_entries SET status = pg_temp.translate_enum(status, '{
  "pago": "paid", "pendente": "pending", "parcial": "partial", "outro": "other"
}'::jsonb)
WHERE status IS NOT NULL;

ALTER TABLE financial_entries ALTER COLUMN status SET DEFAULT 'paid';

-- ============================================================================
-- 14. attachments
-- ============================================================================
UPDATE attachments SET category = pg_temp.translate_enum(category, '{
  "fichaAvaliacao": "assessmentForm", "documento": "document",
  "imagem": "image", "outro": "other"
}'::jsonb)
WHERE category IS NOT NULL;

ALTER TABLE attachments ALTER COLUMN category SET DEFAULT 'other';

-- ============================================================================
-- 15. profiles
-- ============================================================================
ALTER TABLE profiles RENAME COLUMN nome TO name;
ALTER TABLE profiles RENAME COLUMN telefone TO phone;
ALTER TABLE profiles RENAME COLUMN foto_path TO photo_path;

-- ============================================================================
-- Cleanup
-- ============================================================================
DROP FUNCTION IF EXISTS pg_temp.translate_enum(text, jsonb);
DROP FUNCTION IF EXISTS pg_temp.translate_enum_array(jsonb, jsonb);

COMMIT;

-- ============================================================================
-- After running: spot-check a few rows, e.g.
--   SELECT id, name, gender, medical_history, discharge FROM patients LIMIT 5;
--   SELECT id, date, time, patient_name, status FROM appointments LIMIT 5;
--   SELECT id, date, amount, payment_method, status FROM financial_entries LIMIT 5;
-- ============================================================================
