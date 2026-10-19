// Rotina de purga das exclusões de conta com prazo vencido -- PURA (sem Deno.*), testável em Node.
//
// Ordem de segurança por conta: (1) remove os arquivos do Storage pela API e confere que não sobrou nenhum;
// (2) só então pede ao banco para finalizar (finalize_account_deletion), que apaga a conta e grava o log mínimo.
// Se qualquer passo falha, a conta é pulada e tentada de novo na próxima rodada (tudo idempotente).
// Resultado e logs: só contagens e códigos. Nunca id de usuário, nome de arquivo ou erro bruto.

export interface PurgePorts {
  /** Contas com prazo de arrependimento vencido (list_due_account_deletions). */
  listDue(limit: number): Promise<string[]>;
  /** Remove todos os arquivos da conta (anexos e avatar) e devolve quantos AINDA restam. */
  removeStorage(userId: string): Promise<{ remaining: number }>;
  /** finalize_account_deletion: recusa se houver objeto no Storage ou se o prazo não venceu. */
  finalize(userId: string): Promise<void>;
}

export interface PurgeSummary {
  due: number;
  finalized: number;
  skippedStorageNotEmpty: number;
  failed: number;
}

export async function runAccountPurge(ports: PurgePorts, limit = 20): Promise<PurgeSummary> {
  const summary: PurgeSummary = { due: 0, finalized: 0, skippedStorageNotEmpty: 0, failed: 0 };
  const due = await ports.listDue(limit);
  summary.due = due.length;
  for (const userId of due) {
    try {
      const { remaining } = await ports.removeStorage(userId);
      if (remaining > 0) {
        // Nunca apaga a conta com arquivo sobrando: o prontuário é perdido de vez quando o vínculo some.
        summary.skippedStorageNotEmpty++;
        continue;
      }
      await ports.finalize(userId);
      summary.finalized++;
    } catch {
      summary.failed++;
    }
  }
  return summary;
}

export interface StorageLike {
  /** Lista entradas de um prefixo (pastas têm id nulo). Paginada. */
  list(bucket: string, path: string, limit: number, offset: number): Promise<{ name: string; id: string | null }[]>;
  remove(bucket: string, paths: string[]): Promise<void>;
}

const BUCKETS = ["patient-attachments", "avatars"] as const;
const PAGE = 100;

async function listAll(storage: StorageLike, bucket: string, path: string): Promise<{ name: string; id: string | null }[]> {
  const out: { name: string; id: string | null }[] = [];
  for (let offset = 0; ; offset += PAGE) {
    const page = await storage.list(bucket, path, PAGE, offset);
    out.push(...page);
    if (page.length < PAGE) return out;
  }
}

async function collectFiles(storage: StorageLike, bucket: string, userId: string): Promise<string[]> {
  const files: string[] = [];
  for (const entry of await listAll(storage, bucket, userId)) {
    if (entry.id === null) {
      for (const f of await listAll(storage, bucket, `${userId}/${entry.name}`)) {
        if (f.id !== null) files.push(`${userId}/${entry.name}/${f.name}`);
      }
    } else {
      files.push(`${userId}/${entry.name}`);
    }
  }
  return files;
}

/** Remove tudo da conta e reconta; repete algumas rodadas para cobrir paginação e remoções parciais. */
export async function removeUserStorage(storage: StorageLike, userId: string, maxRounds = 5): Promise<{ remaining: number }> {
  let remaining = 0;
  for (let round = 0; round < maxRounds; round++) {
    remaining = 0;
    let removedAny = false;
    for (const bucket of BUCKETS) {
      const files = await collectFiles(storage, bucket, userId);
      remaining += files.length;
      for (let i = 0; i < files.length; i += PAGE) {
        await storage.remove(bucket, files.slice(i, i + PAGE));
        removedAny = true;
      }
    }
    if (remaining === 0) return { remaining: 0 };
    if (!removedAny) break;
  }
  // Confere de novo depois da última remoção.
  let left = 0;
  for (const bucket of BUCKETS) left += (await collectFiles(storage, bucket, userId)).length;
  return { remaining: left };
}
