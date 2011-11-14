define webapp::python::instance($domain,
                                $ensure=present,
                                $aliases=[],
                                $static_dirs=[],
                                $wsgi_module="",
                                $django=false,
                                $django_settings="",
                                $requirements=false,
                                $workers=1,
                                $src="",
                                $venv="",
                                $init=true,
                                $upstart=false) {
  
  if (!$src) {
      $src = "${webapp::python::src_root}/$name"
  }

  if (!$venv) {
      $venv = "${webapp::python::venv_root}/$name"
  }

  $pidfile = "${python::gunicorn::rundir}/${name}.pid"
  $socket = "${python::gunicorn::rundir}/${name}.sock"

  $owner = $webapp::python::owner
  $group = $webapp::python::group

  file { $src:
    ensure => directory,
    owner => $owner,
    group => $group,
  }

  $site_root = "${nginx::root}/${name}"
    
  nginx::site { $name:
    ensure => $ensure,
    domain => $domain,
    aliases => $aliases,
    root => $site_root,
    static_dirs => $static_dirs,
    upstreams => ["unix:${socket}"],
    owner => $owner,
    group => $group,
    #require => Python::Gunicorn::Instance[$name],
  }

  python::venv::isolate { $venv:
    ensure => $ensure,
    requirements => $requirements ? {
      true => "$src/requirements.txt",
      false => undef,
      default => "$src/$requirements",
    },
  }

  python::gunicorn::instance { $name:
    ensure => $ensure,
    venv => $venv,
    src => $src,
    wsgi_module => $wsgi_module,
    django => $django,
    django_settings => $django_settings,
    workers => $workers,
    require => $ensure ? {
      'present' => Python::Venv::Isolate[$venv],
      default => undef,
    },
    before => $ensure ? {
      'absent' => Python::Venv::Isolate[$venv],
      default => undef,
    },
    init => $init,
    upstart => $upstart,
  }

  # Disabling monit for now
  #
  #$reload = $upstart ? {
  #  false => "/etc/init.d/gunicorn-${name} reload",
  #  true => "service gunicorn-$name reload",
  #  default => "service $upstart reload"
  #}
  #
  #monit::monitor { "gunicorn-$name":
  #  ensure => $ensure,
  #  pidfile => $pidfile,
  #  socket => $socket,
  #  checks => ["if totalmem > $monit_memory_limit MB for 2 cycles then exec \"$reload\"",
  #             "if totalmem > $monit_memory_limit MB for 3 cycles then restart",
  #             "if cpu > ${monit_cpu_limit}% for 2 cycles then alert"],
  #  require => $ensure ? {
  #    'present' => Python::Gunicorn::Instance[$name],
  #    default => undef,
  #  },
  #  before => $ensure ? {
  #    'absent' => Python::Gunicorn::Instance[$name],
  #    default => undef,
  #  },
  #}
}
