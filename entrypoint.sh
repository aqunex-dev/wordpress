#!/bin/bash
set -e

WP_CONFIG="/var/www/html/wp-config.php"
EXTRA_FILE="/usr/share/aqn-wp/wp-config.extra.php"

export WP_CONFIG

COMBINED_EXTRA=""

if [ -f "$EXTRA_FILE" ]; then
    echo "Loading dynamic configuration from $EXTRA_FILE..."
    FILE_CONTENT=$(sed -e 's/^<?php//g' -e 's/^<?//g' "$EXTRA_FILE")
    COMBINED_EXTRA="${COMBINED_EXTRA}${FILE_CONTENT}"
fi

if [ -n "$WORDPRESS_CONFIG_EXTRA" ]; then
    echo "Appending WORDPRESS_CONFIG_EXTRA from environment..."
    COMBINED_EXTRA="${COMBINED_EXTRA}
${WORDPRESS_CONFIG_EXTRA}"
fi

if [ -n "$COMBINED_EXTRA" ] && [ -f "$WP_CONFIG" ]; then

    if ! grep -q "WORDPRESS_CONFIG_EXTRA_START" "$WP_CONFIG"; then
        echo "Inserting combined configurations into wp-config.php..."
        
        export EXTRA_CODE="// WORDPRESS_CONFIG_EXTRA_START
${COMBINED_EXTRA}
// WORDPRESS_CONFIG_EXTRA_END"

        if grep -q "That's all, stop editing!" "$WP_CONFIG"; then
            php -r '
                $config = file_get_contents($_SERVER["WP_CONFIG"]);
                $extra = $_SERVER["EXTRA_CODE"];
                $target = "/* That\x27s all, stop editing!";
                
                $updated = str_replace($target, $extra . "\n" . $target, $config);
                file_put_contents($_SERVER["WP_CONFIG"], $updated);
            '
            echo "Successfully injected via PHP."
        else
            echo -e "\n${EXTRA_CODE}" >> "$WP_CONFIG"
        fi
    else
        echo "Configuration already injected. Skipping."
    fi
fi

exec "$@"
