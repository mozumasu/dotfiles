local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
  -- Disable default patterns
  config.disable_default_quick_select_patterns = true
  
  -- Define only custom patterns
  config.quick_select_patterns = {
    -- URL (http/https only)
    '\\bhttps?://[\\w\\-._~:/?#@!$&\'()*+,;=%]+',
    
    -- Email
    '\\b[\\w._%+-]+@[\\w.-]+\\.[a-zA-Z]{2,4}\\b',
    
    -- Git commit hash (7-40 chars, word boundary required)
    '\\b[0-9a-f]{7,40}\\b',
    
    -- IP address
    '\\b(?:[0-9]{1,3}\\.){3}[0-9]{1,3}\\b',
    
    -- AWS ARN (complete ARN starting with 'arn' only)
    '\\barn:[\\w\\-]+:[\\w\\-]+:[\\w\\-]*:[0-9]*:[\\w\\-/:]+',
    
    -- AWS Account ID (12 digits only)
    '\\b[0-9]{12}\\b',
    
    
    -- UUID (hyphen-separated required)
    '\\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\b',
    
    -- S3 URL (starting with s3:// only)
    's3://[a-z0-9][a-z0-9\\-\\.]{1,61}[a-z0-9]',
    
    -- AWS Secrets Manager JSON values
    -- Password-like strings (X characters repeated, common for masked passwords)
    '\\bX{10,}\\b',
    
    -- Alphanumeric strings with special chars (potential passwords, 10+ chars)
    '[A-Za-z0-9!@#$%^&*()_+=\\-]{10,}',
    
    -- RDS hostnames with amazonaws.com
    '[\\w\\-]+\\.(?:cluster-)?[\\w\\-]+\\.[\\w\\-]+\\.rds\\.amazonaws\\.com',
    
    -- Database identifiers (prod-dbcluster, etc.)
    '\\b(?:prod|dev|staging|test)-[\\w\\-]+\\b',
  }
  
  -- Additional QuickSelect settings
  config.quick_select_alphabet = "asdfghjklqwertyuiopzxcvbnm"
end

return module