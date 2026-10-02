#!/usr/bin/env python3
"""Comenta somente a regra obrigatória pam_usb; preserva as demais linhas."""
import argparse
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

ATIVA = re.compile(rb"^[ \t]*auth[ \t]+required[ \t]+pam_usb\.so(?:[ \t]+[^\r\n]*)?[ \t]*$")
COMENTADA = re.compile(rb"^[ \t]*#[ \t]*auth[ \t]+required[ \t]+pam_usb\.so(?:[ \t]+[^\r\n]*)?[ \t]*$")
USB_AUTH = re.compile(rb"^[ \t]*auth[ \t]+.*\bpam_usb\.so\b")


def preparar(dados):
    linhas = dados.splitlines(keepends=True)
    indices = [i for i, linha in enumerate(linhas) if ATIVA.fullmatch(linha.rstrip(b"\r\n"))]
    outras = [linha for linha in linhas if USB_AUTH.match(linha) and not ATIVA.fullmatch(linha.rstrip(b"\r\n"))]
    if outras:
        raise ValueError("Existe outra regra auth do pam_usb no GDM. Revise manualmente; nada foi alterado.")
    if not indices:
        if any(COMENTADA.fullmatch(linha.rstrip(b"\r\n")) for linha in linhas):
            return None
        raise ValueError("Regra 'auth required pam_usb.so' não encontrada; nada foi alterado.")
    if len(indices) != 1:
        raise ValueError("Há regras obrigatórias duplicadas; revise manualmente. Nada foi alterado.")
    linhas[indices[0]] = b"# " + linhas[indices[0]]
    return b"".join(linhas)


def processar(caminho, consultar=False):
    caminho = Path(caminho)
    info = caminho.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError("O destino deve ser um arquivo regular, sem link simbólico.")
    dados = caminho.read_bytes()
    novo = preparar(dados)
    if novo is None:
        print("A regra obrigatória USB no GDM já está comentada. Nenhuma alteração.")
        return 3
    if consultar:
        print("Alteração proposta: comentar somente 'auth required pam_usb.so' em gdm-password.")
        return 0
    temp = None
    try:
        fd, temp = tempfile.mkstemp(prefix=".gdm-password-usb-", dir=caminho.parent)
        with os.fdopen(fd, "wb") as arquivo:
            arquivo.write(novo)
            arquivo.flush()
            os.fchmod(arquivo.fileno(), stat.S_IMODE(info.st_mode))
            if os.geteuid() == 0:
                os.fchown(arquivo.fileno(), info.st_uid, info.st_gid)
            os.fsync(arquivo.fileno())
        atual = caminho.lstat()
        if (atual.st_dev, atual.st_ino, atual.st_mtime_ns, atual.st_size) != (info.st_dev, info.st_ino, info.st_mtime_ns, info.st_size) or caminho.read_bytes() != dados:
            raise ValueError("O arquivo mudou durante a operação. Nada foi substituído; execute novamente.")
        os.replace(temp, caminho)
        temp = None
    finally:
        if temp is not None:
            os.unlink(temp)
    print("Regra USB obrigatória comentada no GDM. As demais linhas foram preservadas.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("arquivo", type=Path)
    parser.add_argument("--check", action="store_true", help="consulta sem gravar")
    args = parser.parse_args()
    try:
        return processar(args.arquivo, args.check)
    except (OSError, ValueError) as exc:
        print(f"Erro: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
