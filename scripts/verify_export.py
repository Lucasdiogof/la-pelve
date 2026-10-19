#!/usr/bin/env python3
"""Confere um pacote de exportacao do La Pelve contra o proprio manifest.json.

Uso: python3 scripts/verify_export.py caminho/para/la-pelve-exportacao-*.zip
Nao envia nada para a rede e nao grava nada. Sai com codigo 1 se algo nao conferir.
Prova consistencia interna do pacote (nada faltando, nada alterado); nao prova autoria,
momento da geracao nem guarda legal.
"""
import hashlib
import json
import sys
import zipfile


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main(path: str) -> int:
    problems = []
    with zipfile.ZipFile(path) as z:
        bad = z.testzip()
        if bad:
            problems.append(f"entrada corrompida no ZIP: {bad}")
        names = {n for n in z.namelist() if not n.endswith("/")}  # ignora entradas de pasta
        manifest = json.loads(z.read("manifest.json"))
        expected = {"manifest.json", "LEIA-ME.txt"}

        for table, info in manifest["tables"].items():
            expected.add(info["file"])
            if info["file"] not in names:
                problems.append(f"falta {info['file']}")
                continue
            data = z.read(info["file"])
            if sha(data) != info["sha256"]:
                problems.append(f"SHA-256 diferente: {info['file']}")
            rows = json.loads(data)
            if len(rows) != info["rows"]:
                problems.append(f"{table}: {len(rows)} linhas no arquivo, manifesto diz {info['rows']}")

        for key in ("attachments", "orphan_files"):
            for item in manifest[key]:
                expected.add(item["zip_path"])
                if item["zip_path"] not in names:
                    problems.append(f"falta {item['zip_path']}")
                    continue
                data = z.read(item["zip_path"])
                if len(data) != item["bytes"] or sha(data) != item["sha256"]:
                    problems.append(f"anexo diferente do manifesto: {item['zip_path']}")

        for extra in sorted(names - expected):
            problems.append(f"arquivo fora do manifesto: {extra}")

        attachment_rows = json.loads(z.read("data/attachments.json"))
        listed = {a["id"] for a in manifest["attachments"]}
        for row in attachment_rows:
            if row["id"] not in listed:
                problems.append(f"anexo {row['id']} esta na tabela mas nao no pacote")

        counts = manifest["counts"]
        print("Contagens:", json.dumps(counts, ensure_ascii=False))
        print("Arquivos no ZIP:", len(names))

    if problems:
        print("\nPROBLEMAS:")
        for p in problems:
            print(" -", p)
        return 1
    print("\nOK: todos os arquivos conferem com o manifesto.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
