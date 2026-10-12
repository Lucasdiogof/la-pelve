/** SHA-256 em hexadecimal (minúsculo) de um texto UTF-8. Usado só para identificar segredos sem expô-los. */
export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
