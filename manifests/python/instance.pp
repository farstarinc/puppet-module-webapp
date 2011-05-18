define webapp::python::instance($domain,
                                $ensure=present,
                                $aliases=[],
                                $owner="www-data",
                                $group="www-data",
                                $mediaroot="",
                                $mediaprefix="",
                                $wsgi_module="",
                                $django=false,
                                $requirements=false,
                                $workers=1,
                                $monit_memory_limit=300,
                                $monit_cpu_limit=50) {

  $venv = "${webapp::python::venv_root}/$name"
  $src = "${webapp::python::src_root}/$name"

  $pidfile = "${python::gunicorn::rundir}/${name}.pid"
  $socket = "${python::gunicorn::rundir}/${name}.sock"

  nginx::site { $name:
    ensure => $ensure,
    domain => $domain,
    aliases => $aliases,
    root => "/var/www/$name",
    mediaroot => $mediaroot,
    mediaprefix => $mediaprefix,
    upstreams => ["unix:${socket}"],
    owner => $owner,
    group => $group,
    require => Python::Gunicorn::Instance[$name],
  }

  python::venv::isolate { $venv:
    ensure => $ensure,
    requirements => $requirements ? {
      true => "$src/requirements.txt",
      default => undef,
    },
  }

  python::gunicorn::instance { $name:
    ensure => $ensure,
    venv => $venv,
    src => $src,
    wsgi_module => $wsgi_module,
    django => $django,
    workers => $workers,
    require => Python::Venv::Isolate[$name],
  }

  $reload = "/etc/init.d/gunicorn-$name reload"

  monit::monitor { "gunicorn-$name":
    ensure => $ensure,
    pidfile => $pidfile,
    socket => $socket,
    checks => ["if totalmem > $monit_memory_limit for 2 cycles then exec \"$reload\"",
               "if totalmem > $monit_memory_limit MB for 3 cycles then restart",
               "if cpu > ${monit_cpu_limit}% for 2 cycles then alert"],
    require => Python::Gunicorn::Instance[$name],
  }
}
