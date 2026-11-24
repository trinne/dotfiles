# as_root CMD...: run CMD as root, directly when already root, otherwise via sudo
# (keeping proxy/token variables). can_root: true if as_root works without a password prompt.
can_root() { [[ $(id -u) -eq 0 ]] || sudo -n true 2>/dev/null; }
as_root() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
  else
    sudo "--preserve-env=GITHUB_TOKEN,HTTPS_PROXY,HTTP_PROXY,https_proxy,http_proxy,NO_PROXY,no_proxy,SSL_CERT_FILE" "$@"
  fi
}
