"""Testes em arquivos temporários; não acessam o PAM real do computador."""
import importlib.util
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('editar_gdm', ROOT / 'scripts/lib/editar-gdm.py')
editar = importlib.util.module_from_spec(spec)
spec.loader.exec_module(editar)

EXEMPLO = b'#%PAM-1.0\nauth requisite pam_nologin.so\nauth\trequired\tpam_usb.so\n@include common-auth\nauth optional pam_gnome_keyring.so\n'


class RecuperacaoTest(unittest.TestCase):
    def test_preserva_demais_linhas_e_permissoes(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'gdm-password'
            p.write_bytes(EXEMPLO)
            p.chmod(0o640)
            self.assertEqual(editar.processar(p), 0)
            self.assertEqual(p.read_bytes(), EXEMPLO.replace(b'auth\trequired\tpam_usb.so', b'# auth\trequired\tpam_usb.so'))
            self.assertEqual(stat.S_IMODE(p.stat().st_mode), 0o640)
            self.assertEqual(list(Path(tmp).glob('.gdm-password-usb-*')), [])
            depois = p.read_bytes()
            self.assertEqual(editar.processar(p), 3)
            self.assertEqual(p.read_bytes(), depois)

    def test_consulta_nao_grava(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / 'gdm-password'
            p.write_bytes(EXEMPLO)
            inode = p.stat().st_ino
            self.assertEqual(editar.processar(p, consultar=True), 0)
            self.assertEqual(p.read_bytes(), EXEMPLO)
            self.assertEqual(p.stat().st_ino, inode)

    def test_recusa_duplicacao_regra_diferente_ou_ausencia(self):
        entradas = [EXEMPLO + b'auth required pam_usb.so\n', EXEMPLO.replace(b'required\tpam_usb.so', b'sufficient\tpam_usb.so'), b'@include common-auth\n']
        for dados in entradas:
            with self.subTest(dados=dados), tempfile.TemporaryDirectory() as tmp:
                p = Path(tmp) / 'gdm-password'
                p.write_bytes(dados)
                with self.assertRaises(ValueError):
                    editar.processar(p)
                self.assertEqual(p.read_bytes(), dados)

    def test_recusa_link_simbolico(self):
        with tempfile.TemporaryDirectory() as tmp:
            real = Path(tmp) / 'real'
            real.write_bytes(EXEMPLO)
            link = Path(tmp) / 'link'
            link.symlink_to(real)
            with self.assertRaises(ValueError):
                editar.processar(link)
            self.assertEqual(real.read_bytes(), EXEMPLO)

    def test_preserva_crlf_e_sem_quebra_final(self):
        for dados in (EXEMPLO.replace(b'\n', b'\r\n'), b'auth required pam_usb.so'):
            with self.subTest(dados=dados):
                self.assertEqual(editar.preparar(dados), dados.replace(b'auth', b'# auth', 1) if dados.startswith(b'auth') else dados.replace(b'auth\trequired\tpam_usb.so', b'# auth\trequired\tpam_usb.so'))

    def test_opcoes_na_regra_sao_preservadas(self):
        self.assertEqual(editar.preparar(b'  auth required pam_usb.so debug\n'), b'#   auth required pam_usb.so debug\n')


class ShellTest(unittest.TestCase):
    def test_sintaxe_e_ajuda(self):
        for script in sorted((ROOT / 'scripts').rglob('*.sh')):
            with self.subTest(script=script.name):
                subprocess.run(['bash', '-n', str(script)], check=True, capture_output=True)
                if script.parent == ROOT / 'scripts':
                    result = subprocess.run(['bash', str(script), '--help'], check=True, capture_output=True, text=True)
                    self.assertIn('Uso:', result.stdout)

    def test_recuperador_recusa_entrada_nao_interativa(self):
        result = subprocess.run(['bash', str(ROOT / 'scripts/recuperar-acesso.sh')], input='CONFIRMAR\n', capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue('terminal interativo' in result.stderr or 'sudo' in result.stderr)

    def test_argumentos_invalidos(self):
        for script in (ROOT / 'scripts').glob('*.sh'):
            result = subprocess.run(['bash', str(script), '--argumento-invalido', 'extra'], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
