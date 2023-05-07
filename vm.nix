{ pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    tmux
    neovim
    htop
  ];
}
