# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Class: cgit
#
class cgit(
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
) {

  include apache

  package { [
      'cgit',
      'git-daemon',
    ]:
    ensure => present,
  }

  user { 'cgit':
    ensure     => present,
    home       => '/home/cgit',
    shell      => '/bin/bash',
    gid        => 'cgit',
    managehome => true,
    require    => Group['cgit'],
  }

  group { 'cgit':
    ensure => present,
  }

  file {'/home/cgit':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0755',
    require => User['cgit'],
  }

  file { '/var/lib/git':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0644',
    require => User['cgit'],
  }

  exec { 'restorecon -R -v /var/lib/git':
    path        => '/sbin',
    require     => File['/var/lib/git'],
    subscribe   => File['/var/lib/git'],
    refreshonly => true,
  }

  selboolean { 'httpd_enable_cgi':
    persistent => true,
    value      => on
  }

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'cgit/git.vhost.erb',
    ssl      => true,
  }

  file { '/etc/xinetd.d/git':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/cgit/git.xinetd',
  }

  service { 'xinetd':
    ensure    => running,
    subscribe => File['/etc/xinetd.d/git'],
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }
}
