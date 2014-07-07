<?php
        // MySQL Connection Information
        // The following values corrospond to databases.cfg
        //$config = new stdClass;

        class DynamicProperties { }
        $config = new DynamicProperties;

        $config->my_hostname            = '';
        $config->my_database            = '';
        $config->my_user                        = '';
        $config->my_pass                        = '';

        // Server information for page display
        $config->my_server_name = '';

        // Path to Logo
        $config->my_logo_path           = 'http://war3source.com/wiki/images/war3wikilogo.gif';

        // Path to Homepage
        $config->my_home_path           = 'http://war3source.com';

// DO NOT CHANGE BELOW THIS LINE
// DO NOT CHANGE BELOW THIS LINE
// DO NOT CHANGE BELOW THIS LINE
//_____________________________________________________________________________________________________//

        // DO NOT CHANGE UNLESS YOU KNOW WHAT YOUR DOING
        $config->my_war3source_table                    = 'war3source';
        $config->my_war3sourceraces_table               = 'war3sourceraces';
        $config->my_war3sourceraces_data_table          = 'war3source_racedata1';
?>
