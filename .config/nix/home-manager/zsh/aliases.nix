{
  programs.zsh.shellAliases = {
    # CLI wrappers
    aws = "aws-wrapper";

    v = "nvim";
    "..." = "../../";
    "...." = "../../../";
    "....." = "../../../../";

    # rm
    gm = "gomi";

    # aws
    awsp = "set-aws-profile";
    awsvl = "aws-vault-login";
    ec2ls = "(echo -e \"InstanceId\\tName\\tPublicIpAddress\" && aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]' --output text) | column -t";
    wsls = "get-workspaces-info";
    awsip = "get-aws-service-ip";
    iam = "check-iam-policy";
    ssmdv = "view-ssm-document";
    ssmdsync = "sync-ssm-document";
    awsconfig = "v ~/.aws/config";
    awscredentials = "v ~/.aws/credentials";

    # function alias
    sshf = "fzf-ssh";
    gi = "create-gitignore";

    # Claude
    claudeconfig = "v ~/Library/Application\\ Support/Claude/claude_desktop_config.json";

    # Mac - karabiner
    killkara = "sudo killall karabiner_grabber";

    # vpnutil
    vpns = "check-vpn-status";
    vpnc = "vpn-connect-with-fzf";
    vpnd = "vpn-disconnect-if-connected";

    # notification
    beep = "for i in {1..3}; do afplay /System/Library/Sounds/Submarine.aiff; done";

    # zmv
    mmv = "noglob zmv -W";
  };
}
