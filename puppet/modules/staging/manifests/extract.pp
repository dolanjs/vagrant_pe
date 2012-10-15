# Define: staging::extract
#
#   Define resource to extract files from staging directories to target
#   directories.
#
# Parameters:
#
#   * target: the target extraction directory,
#   * source: the source compression file, supports tar, tar.gz, zip, war. if
#   unspecified defaults to ${staging::path}/${caller_module_name}/${name}
#   * creates: the file created after extraction. if unspecified defaults to
#   ${target}/${name}.
#   * unless: alternative way to conditionally check whether to extract file.
#   * onlyif: alternative way to conditionally check whether to extract file.
#   * user: extract file as this user.
#   * group: extract file as this group.
#   * environments: environment variables.
#   * subdir: subdir per module in staging directory.
#
# Usage:
#
#   staging::extract { 'apache-tomcat-6.0.35':
#     target => '/opt',
#     owner  => 'tomcat',
#     group  => 'tomcat',
#   }
#
define staging::extract (
  $target,
  $source      = undef,
  $creates     = undef,
  $unless      = undef,
  $onlyif      = undef,
  $user        = undef,
  $group       = undef,
  $environment = undef,
  # allowing pass through of real caller.
  $subdir      = $caller_module_name
) {

  include staging

  if $source {
    $source_path = $source
  } else {
    $source_path = "${staging::path}/${subdir}/${name}"
  }

  # Use user supplied creates path, set default value if creates, unless or
  # onlyif is not supplied.
  if $creates {
    $creates_path = $creates
  } elsif ! ($unless or $onlyif) {
    if $name =~ /.tar.gz$/ {
      $folder       = staging_parse($name, 'basename', '.tar.gz')
      $creates_path = "${target}/${folder}"
    } else {
      $folder       = staging_parse($name, 'basename')
      $creates_path = "${target}/${folder}"
    }
  }

  if scope_defaults('Exec','path') {
    Exec{
      cwd         => $target,
      user        => $user,
      group       => $group,
      environment => $environment,
      creates     => $creates_path,
      unless      => $unless,
      onlyif      => $onlyif,
      logoutput   => on_failure,
    }
  } else {
    Exec{
      path        => $::path,
      cwd         => $target,
      user        => $user,
      group       => $group,
      environment => $environment,
      creates     => $creates_path,
      unless      => $unless,
      onlyif      => $onlyif,
      logoutput   => on_failure,
    }
  }

  case $name {
    /.tar$/: {
      $command = "tar xf ${source_path}"
    }

    /(.tgz|.tar.gz)$/: {
      if $::osfamily == 'Solaris' {
        $command = "gunzip -dc < ${source_path} | tar xf - "
      } else {
        $command = "tar xzf ${source_path}"
      }
    }

    /.zip$/: {
      $command = "unzip ${source_path}"
    }

    /.war$/: {
      $command = "jar xf ${source_path}"
    }

    default: {
      fail("staging::extract: unsupported file format ${name}.")
    }
  }

  exec { "extract ${name}":
    command => $command,
  }
}
