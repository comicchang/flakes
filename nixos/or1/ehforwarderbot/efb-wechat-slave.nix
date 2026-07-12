{
  lib,
  source,
  buildPythonPackage,
  setuptools_80,
  ehforwarderbot,
  python-magic,
  pillow,
  pyqrcode,
  pypng,
  pyyaml,
  requests,
  typing-extensions,
  bullet,
  cjkwrap,
}:
buildPythonPackage {
  inherit (source) pname version src;

  pyproject = true;
  build-system = [
    setuptools_80
  ];

  dependencies = [
    setuptools_80
    ehforwarderbot
    python-magic
    requests
    pillow
    pyqrcode
    pypng
    pyyaml
    bullet
    cjkwrap
    typing-extensions
  ];

  meta = {
    description = "WeChat Slave Channel for EH Forwarder Bot, based on WeChat Web API.";
    homepage = "https://github.com/ehForwarderBot/efb-wechat-slave";
    license = lib.licenses.agpl3Plus;
  };
}
