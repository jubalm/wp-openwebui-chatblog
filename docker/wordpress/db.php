<?php
/**
 * Plugin Name: WP SQLite DB
 * Description: SQLite database driver drop-in. (based on SQLite Integration by Kojima Toshiyasu)
 * Author: Evan Mattson
 * Author URI: https://aaemnnost.tv
 * Plugin URI: https://github.com/aaemnnosttv/wp-sqlite-db
 * Version: 1.3.1
 * Requires PHP: 5.6
 *
 * This file must be placed in wp-content/db.php.
 * WordPress loads this file automatically.
 *
 * This project is based on the original work of Kojima Toshiyasu and his SQLite Integration plugin.
 */

namespace WP_SQLite_DB {

    use DateTime;
    use DateInterval;
    use PDO;
    use PDOException;
    use SQLite3;

    if (! defined('ABSPATH')) {
        exit;
    }

    /**
     * USE_MYSQL is a directive for using MySQL for database.
     * If you want to change the database from SQLite to MySQL or from MySQL to SQLite,
     * the line below in the wp-config.php will enable you to use MySQL.
     *
     * <code>
     * define('USE_MYSQL', true);
     * </code>
     *
     * If you want to use SQLite, the line below will do. Or simply removing the line will
     * be enough.
     *
     * <code>
     * define('USE_MYSQL', false);
     * </code>
     */
    if (defined('USE_MYSQL') && USE_MYSQL) {
        return;
    }

    function pdo_log_error($message, $data = null)
    {
        if (defined('WP_DEBUG_LOG') && WP_DEBUG_LOG) {
            if (is_array($data) || is_object($data)) {
                error_log('[WP_SQLite_DB] ' . $message . ' - ' . print_r($data, true));
            } else {
                error_log('[WP_SQLite_DB] ' . $message . ($data ? ' - ' . $data : ''));
            }
        }
    }

    // Set default database location
    if (! defined('DB_DIR')) {
        define('DB_DIR', ABSPATH . 'wp-content/database/');
    }

    if (! defined('DB_FILE')) {
        define('DB_FILE', 'wordpress.sqlite');
    }

    // Create database directory if it doesn't exist
    if (! is_dir(DB_DIR)) {
        if (! wp_mkdir_p(DB_DIR)) {
            pdo_log_error('Failed to create database directory: ' . DB_DIR);
        }
    }

    // Create .htaccess file to protect database
    $htaccess_file = DB_DIR . '.htaccess';
    if (! file_exists($htaccess_file)) {
        $htaccess_content = "# Protect database files\n<Files ~ \"\\.(sqlite|db)$\">\n    Order allow,deny\n    Deny from all\n</Files>\n";
        file_put_contents($htaccess_file, $htaccess_content);
    }

    /**
     * This is the main class for the database engine.
     * It extends PDO and implements the WordPress database interface.
     */
    class PDOEngine extends PDO
    {
        /**
         * Database connection handle
         */
        private $dbh;
        
        /**
         * Query result handle
         */
        private $result;
        
        /**
         * Query string
         */
        private $query;
        
        /**
         * Whether to show errors
         */
        private $show_errors = false;
        
        /**
         * Number of rows affected by the last query
         */
        private $affected_rows = 0;
        
        /**
         * Number of rows returned by the last query
         */
        private $num_rows = 0;
        
        /**
         * Last insert ID
         */
        private $insert_id = 0;
        
        /**
         * Constructor
         */
        public function __construct()
        {
            $database_file = DB_DIR . DB_FILE;
            
            try {
                parent::__construct('sqlite:' . $database_file, null, null, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ,
                    PDO::ATTR_STRINGIFY_FETCHES => false,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]);
                
                $this->dbh = $this;
                $this->init_sqlite_functions();
                
                pdo_log_error('SQLite database connected: ' . $database_file);
                
            } catch (PDOException $e) {
                pdo_log_error('Database connection failed: ' . $e->getMessage());
                wp_die('Database connection failed: ' . $e->getMessage());
            }
        }
        
        /**
         * Initialize SQLite user-defined functions
         */
        private function init_sqlite_functions()
        {
            // MySQL compatibility functions
            $this->exec('PRAGMA foreign_keys = ON');
            $this->exec('PRAGMA journal_mode = WAL');
            $this->exec('PRAGMA synchronous = NORMAL');
            $this->exec('PRAGMA cache_size = 10000');
            $this->exec('PRAGMA temp_store = MEMORY');
            
            // Add MySQL-compatible functions
            $this->sqliteCreateFunction('NOW', function() {
                return date('Y-m-d H:i:s');
            });
            
            $this->sqliteCreateFunction('UNIX_TIMESTAMP', function($date = null) {
                return $date ? strtotime($date) : time();
            });
            
            $this->sqliteCreateFunction('FROM_UNIXTIME', function($timestamp) {
                return date('Y-m-d H:i:s', $timestamp);
            });
            
            $this->sqliteCreateFunction('SUBSTRING', function($string, $start, $length = null) {
                return $length ? substr($string, $start - 1, $length) : substr($string, $start - 1);
            });
            
            $this->sqliteCreateFunction('LOCATE', function($needle, $haystack, $offset = 0) {
                $pos = strpos($haystack, $needle, $offset);
                return $pos === false ? 0 : $pos + 1;
            });
            
            $this->sqliteCreateFunction('FIELD', function($needle, ...$haystack) {
                $pos = array_search($needle, $haystack);
                return $pos === false ? 0 : $pos + 1;
            });
            
            $this->sqliteCreateFunction('CONCAT', function(...$args) {
                return implode('', $args);
            });
            
            $this->sqliteCreateFunction('REGEXP', function($pattern, $subject) {
                return preg_match('/' . $pattern . '/', $subject);
            });
        }
        
        /**
         * Execute a query
         */
        public function query($query)
        {
            $this->query = $query;
            
            try {
                $this->result = parent::query($query);
                $this->num_rows = $this->result ? $this->result->rowCount() : 0;
                $this->affected_rows = $this->rowCount();
                $this->insert_id = $this->lastInsertId();
                
                return $this->result;
                
            } catch (PDOException $e) {
                pdo_log_error('Query failed: ' . $e->getMessage(), $query);
                if ($this->show_errors) {
                    wp_die('Database query failed: ' . $e->getMessage());
                }
                return false;
            }
        }
        
        /**
         * Get the number of rows affected by the last query
         */
        public function get_affected_rows()
        {
            return $this->affected_rows;
        }
        
        /**
         * Get the number of rows returned by the last query
         */
        public function get_num_rows()
        {
            return $this->num_rows;
        }
        
        /**
         * Get the last insert ID
         */
        public function get_insert_id()
        {
            return $this->insert_id;
        }
        
        /**
         * Show/hide errors
         */
        public function show_errors($show = true)
        {
            $this->show_errors = $show;
        }
        
        /**
         * Get the last query
         */
        public function get_last_query()
        {
            return $this->query;
        }
    }
    
    /**
     * WordPress database compatibility layer
     */
    class WordPressDB extends PDOEngine
    {
        /**
         * WordPress database tables
         */
        public $posts;
        public $users;
        public $options;
        public $postmeta;
        public $usermeta;
        public $terms;
        public $term_taxonomy;
        public $term_relationships;
        public $comments;
        public $commentmeta;
        public $links;
        
        /**
         * Table prefix
         */
        public $prefix;
        
        /**
         * Base prefix
         */
        public $base_prefix;
        
        /**
         * Constructor
         */
        public function __construct()
        {
            parent::__construct();
            
            global $table_prefix;
            $this->prefix = $table_prefix;
            $this->base_prefix = $table_prefix;
            
            $this->set_table_names();
        }
        
        /**
         * Set table names
         */
        private function set_table_names()
        {
            $this->posts = $this->prefix . 'posts';
            $this->users = $this->prefix . 'users';
            $this->options = $this->prefix . 'options';
            $this->postmeta = $this->prefix . 'postmeta';
            $this->usermeta = $this->prefix . 'usermeta';
            $this->terms = $this->prefix . 'terms';
            $this->term_taxonomy = $this->prefix . 'term_taxonomy';
            $this->term_relationships = $this->prefix . 'term_relationships';
            $this->comments = $this->prefix . 'comments';
            $this->commentmeta = $this->prefix . 'commentmeta';
            $this->links = $this->prefix . 'links';
        }
        
        /**
         * Get a single variable from the database
         */
        public function get_var($query = null, $x = 0, $y = 0)
        {
            $result = $this->query($query);
            if ($result) {
                $row = $result->fetch();
                if ($row) {
                    $values = array_values((array) $row);
                    return isset($values[$x]) ? $values[$x] : null;
                }
            }
            return null;
        }
        
        /**
         * Get a single row from the database
         */
        public function get_row($query = null, $output = OBJECT, $y = 0)
        {
            $result = $this->query($query);
            if ($result) {
                $row = $result->fetch();
                if ($row) {
                    if ($output == ARRAY_A) {
                        return (array) $row;
                    } elseif ($output == ARRAY_N) {
                        return array_values((array) $row);
                    } else {
                        return $row;
                    }
                }
            }
            return null;
        }
        
        /**
         * Get multiple rows from the database
         */
        public function get_results($query = null, $output = OBJECT)
        {
            $result = $this->query($query);
            if ($result) {
                $rows = $result->fetchAll();
                if ($output == ARRAY_A) {
                    return array_map(function($row) { return (array) $row; }, $rows);
                } elseif ($output == ARRAY_N) {
                    return array_map(function($row) { return array_values((array) $row); }, $rows);
                } else {
                    return $rows;
                }
            }
            return [];
        }
        
        /**
         * Get a column from the database
         */
        public function get_col($query = null, $x = 0)
        {
            $result = $this->query($query);
            if ($result) {
                $rows = $result->fetchAll();
                $column = [];
                foreach ($rows as $row) {
                    $values = array_values((array) $row);
                    if (isset($values[$x])) {
                        $column[] = $values[$x];
                    }
                }
                return $column;
            }
            return [];
        }
        
        /**
         * Insert a row into the database
         */
        public function insert($table, $data, $format = null)
        {
            $columns = implode(', ', array_keys($data));
            $placeholders = ':' . implode(', :', array_keys($data));
            $sql = "INSERT INTO $table ($columns) VALUES ($placeholders)";
            
            $stmt = $this->prepare($sql);
            foreach ($data as $key => $value) {
                $stmt->bindValue(":$key", $value);
            }
            
            if ($stmt->execute()) {
                $this->insert_id = $this->lastInsertId();
                $this->affected_rows = $stmt->rowCount();
                return true;
            }
            return false;
        }
        
        /**
         * Update rows in the database
         */
        public function update($table, $data, $where, $format = null, $where_format = null)
        {
            $set_clause = [];
            foreach ($data as $key => $value) {
                $set_clause[] = "$key = :$key";
            }
            $set_clause = implode(', ', $set_clause);
            
            $where_clause = [];
            foreach ($where as $key => $value) {
                $where_clause[] = "$key = :where_$key";
            }
            $where_clause = implode(' AND ', $where_clause);
            
            $sql = "UPDATE $table SET $set_clause WHERE $where_clause";
            
            $stmt = $this->prepare($sql);
            foreach ($data as $key => $value) {
                $stmt->bindValue(":$key", $value);
            }
            foreach ($where as $key => $value) {
                $stmt->bindValue(":where_$key", $value);
            }
            
            if ($stmt->execute()) {
                $this->affected_rows = $stmt->rowCount();
                return true;
            }
            return false;
        }
        
        /**
         * Delete rows from the database
         */
        public function delete($table, $where, $where_format = null)
        {
            $where_clause = [];
            foreach ($where as $key => $value) {
                $where_clause[] = "$key = :$key";
            }
            $where_clause = implode(' AND ', $where_clause);
            
            $sql = "DELETE FROM $table WHERE $where_clause";
            
            $stmt = $this->prepare($sql);
            foreach ($where as $key => $value) {
                $stmt->bindValue(":$key", $value);
            }
            
            if ($stmt->execute()) {
                $this->affected_rows = $stmt->rowCount();
                return true;
            }
            return false;
        }
        
        /**
         * Escape string for database
         */
        public function _escape($string)
        {
            return $this->quote($string);
        }
        
        /**
         * Real escape string
         */
        public function _real_escape($string)
        {
            return $this->quote($string);
        }
        
        /**
         * Prepare query
         */
        public function prepare($query, ...$args)
        {
            return parent::prepare($query);
        }
        
        /**
         * Print error
         */
        public function print_error($str = '')
        {
            if ($this->show_errors) {
                echo $str;
            }
        }
    }
    
    // Create global database instance
    if (! isset($GLOBALS['wpdb'])) {
        $GLOBALS['wpdb'] = new WordPressDB();
    }
    
    // WordPress database constants
    if (! defined('DB_NAME')) {
        define('DB_NAME', 'wordpress');
    }
    if (! defined('DB_USER')) {
        define('DB_USER', 'sqlite');
    }
    if (! defined('DB_PASSWORD')) {
        define('DB_PASSWORD', '');
    }
    if (! defined('DB_HOST')) {
        define('DB_HOST', 'localhost');
    }
    if (! defined('DB_CHARSET')) {
        define('DB_CHARSET', 'utf8');
    }
    if (! defined('DB_COLLATE')) {
        define('DB_COLLATE', '');
    }
}