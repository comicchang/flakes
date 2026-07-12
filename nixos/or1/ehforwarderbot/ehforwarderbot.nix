{
  source,
  buildPythonPackage,
  setuptools_80,
  ruamel-yaml,
  bullet,
  cjkwrap,
  typing-extensions,
  lib,
}:
buildPythonPackage {
  inherit (source) pname version src;

  pyproject = true;
  build-system = [
    setuptools_80
  ];

  dependencies = [
    setuptools_80
    ruamel-yaml
    bullet
    cjkwrap
    typing-extensions
  ];

  meta = {
    description = "An extensible message tunneling chat bot framework.";
    homepage = "https://github.com/ehForwarderBot/ehForwarderBot";
    license = lib.licenses.agpl3Plus;
  };
}
