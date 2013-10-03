A very simple Puppet module for configuring the w32time service.

This module requires the puppetlabs/registry module.

# Examples #

Using default settings:

    include 'winntp'

Set all the parameters:

    class { 'winntp':
        special_poll_interval      => 1800, # 30 minutes
        ntp_server                 => 'north-america.pool.ntp.org', # can use comma separated list
        max_pos_phase_correction   => 54000, # 15 hours
        max_neg_phase_correction   => 54000, # 15hours
    }