class webapp::python(owner="www-data",
                     group="www-data",
                     src_root="/usr/local/src",
                     venv_root="/usr/local/venv",
                     nginx_workers=1,
                     monit_admin="",
                     monit_interval=60) {

  class { "nginx": workers => $nginx_workers }
  include python::dev
  include python::venv
  class { "python::gunicorn": owner => $owner, group => $group }
  class { monit: admin => $monit_admin, interval => $monit_interval }

}

