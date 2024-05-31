# SUSE's openQA tests
#
# Copyright SUSE LLC
# SPDX-License-Identifier: FSFAP
# Maintainer: QE-SAP <qe-sap@suse.de>
# Summary:  Executes setup of HanaSR scenario using SDAF ansible playbooks according to:
#           https://learn.microsoft.com/en-us/azure/sap/automation/tutorial#sap-application-installation
# Playbooks can be found in SDAF repo: https://github.com/Azure/sap-automation/tree/main/deploy/ansible

# Required OpenQA variables:
#     'SDAF_ENV_CODE'  Code for SDAF deployment env.
#     'SDAF_WORKLOAD_VNET_CODE' Virtual network code for workload zone.
#     'PUBLIC_CLOUD_REGION' SDAF internal code for azure region.
#     'SAP_SID' SAP system ID.
#     'SDAF_DEPLOYER_RESOURCE_GROUP' Existing deployer resource group - part of the permanent cloud infrastructure.

# Optional:
#     'SDAF_ANSIBLE_VERBOSITY_LEVEL' Override default verbosity for 'ansible-playbook'.

use parent 'sles4sap::microsoft_sdaf_basetest';
use strict;
use warnings;
use sles4sap::sdaf_deployment_library;
use sles4sap::console_redirection;
use serial_terminal qw(select_serial_terminal);
use testapi;

sub test_flags {
    return {fatal => 1};
}

sub run {
    serial_console_diag_banner('Module sdaf_deploy_hanasr.pm : start');
    my $sdaf_config_root_dir = get_sdaf_config_path(
        deployment_type => 'sap_system',
        vnet_code => get_required_var('SDAF_WORKLOAD_VNET_CODE'),
        env_code => get_required_var('SDAF_ENV_CODE'),
        sdaf_region_code => convert_region_to_short(get_required_var('PUBLIC_CLOUD_REGION')),
        sap_sid => get_required_var('SAP_SID')
    );

    # List of playbooks (and their options) to be executed. Keep them in list to be ordered. Each entry must be an ARRAYREF.
    my @execute_playbooks = (
        {playbook_filename => 'pb_get-sshkey.yaml', timeout => 90},
        {playbook_filename => 'playbook_00_validate_parameters.yaml', timeout => 120},
        {playbook_filename => 'playbook_01_os_base_config.yaml'},
        {playbook_filename => 'playbook_02_os_sap_specific_config.yaml'},
        {playbook_filename => 'playbook_04_00_00_db_install.yaml'},
        {playbook_filename => 'playbook_04_00_01_db_ha.yaml'},
        {playbook_filename => 'playbook_07_00_00_post_installation.yaml'},
        {playbook_filename => 'playbook_08_00_00_post_configuration_actions.yaml'}
    );

    connect_target_to_serial();
    load_os_env_variables();

    for my $playbook_options (@execute_playbooks) {
        sdaf_execute_playbook(%{$playbook_options}, sdaf_config_root_dir => $sdaf_config_root_dir);
    }

    disconnect_target_from_serial();
    serial_console_diag_banner('Module sdaf_deploy_hanasr.pm : stop');
}

1;
