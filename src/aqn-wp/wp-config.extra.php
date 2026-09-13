<?php
define( 'DB_NAME',     getenv('WORDPRESS_DB_NAME') ?: 'default_db' );
define( 'DB_USER',     getenv('WORDPRESS_DB_USER') ?: 'default_user' );
define( 'DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: 'default_password' );
define( 'DB_HOST',     getenv('WORDPRESS_DB_HOST') ?: 'localhost' );

if ( getenv('WORDPRESS_DEBUG') === 'true' ) {
    define( 'WP_DEBUG', true );
} else {
    define( 'WP_DEBUG', false );
}
