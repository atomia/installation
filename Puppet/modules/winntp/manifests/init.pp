class winntp (
  $special_poll_interval    = 900, # 15 minutes
  $ntp_server               = 'north-america.pool.ntp.org,time.windows.com',
  $max_pos_phase_correction = '0xFFFFFFFF', # unlimited
  $max_neg_phase_correction = '0xFFFFFFFF') {
    
  include 'registry'

  service { 'w32time':
    ensure => 'running',
  }

  # Info on these settings at http://technet.microsoft.com/en-us/library/cc773263(v=ws.10).aspx

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\Type':
    ensure => present,
    type   => 'string',
    data   => 'NTP',
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config\AnnounceFlags':
    ensure => present,
    type   => 'dword',
    data   => '5',
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient\SpecialPollInterval':
    ensure => present,
    type   => 'dword',
    data   => $special_poll_interval,
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer\Enabled':
    ensure => present,
    type   => 'dword',
    data   => '1',
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters\NtpServer':
    ensure => present,
    type   => 'string',
    data   => $ntp_server,
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config\MaxPosPhaseCorrection':
    ensure => present,
    type   => 'dword',
    data   => $max_pos_phase_correction,
    notify => Service['w32time'],
  }

  registry_value { 'HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config\MaxNegPhaseCorrection':
    ensure => present,
    type   => 'dword',
    data   => $max_neg_phase_correction,
    notify => Service['w32time'],
  }

}