#
# Setup SSH settings and public keys
#

# Load utility functions
. ./functions.sh

if [ "$ENABLE_SSHD" = true ] ; then
  if [ "$SSH_ENABLE_ROOT" = false ] ; then
    # User root is not allowed to log in
    sed -i "s|[#]*PermitRootLogin.*|PermitRootLogin no|g" "${ETC_DIR}/ssh/sshd_config"
  fi

  if [ "$ENABLE_ROOT" = true ] && [ "$SSH_ENABLE_ROOT" = true ] ; then
    # Permit SSH root login
    sed -i "s|[#]*PermitRootLogin.*|PermitRootLogin yes|g" "${ETC_DIR}/ssh/sshd_config"

    # Create root SSH config directory
    mkdir -p "${R}/root/.ssh"

    # Set permissions of root SSH config directory
    chroot_exec chmod 700 "/root/.ssh"
    chroot_exec chown root:root "/root/.ssh"

    # Install SSH (v2) authorized keys file for user root
    if [ ! -z "$SSH_ROOT_AUTHORIZED_KEYS" ] ; then
      install_readonly "$SSH_ROOT_AUTHORIZED_KEYS" "${R}/root/.ssh/authorized_keys2"
    fi

    # Add SSH (v2) public key for user root
    if [ ! -z "$SSH_ROOT_PUB_KEY" ] ; then
      cat "$SSH_ROOT_PUB_KEY" >> "${R}/root/.ssh/authorized_keys2"
    fi

    # Set permissions of root SSH authorized keys file
    if [ -f "${R}/root/.ssh/authorized_keys2" ] ; then
      chroot_exec chmod 600 "/root/.ssh/authorized_keys2"
      chroot_exec chown root:root "/root/.ssh/authorized_keys2"

      # Allow SSH public key authentication
      sed -i "s|[#]*PubkeyAuthentication.*|PubkeyAuthentication yes|g" "${ETC_DIR}/ssh/sshd_config"
    fi
  fi

  # Create $USER_NAME SSH config directory
  mkdir -p "${R}/home/${USER_NAME}/.ssh"

  # Set permissions of $USER_NAME SSH config directory
  chroot_exec chmod 700 "/home/${USER_NAME}/.ssh"
  chroot_exec chown ${USER_NAME}:${USER_NAME} "/home/${USER_NAME}/.ssh"

  # Install SSH (v2) authorized keys file for user $USER_NAME
  if [ ! -z "$SSH_USER_AUTHORIZED_KEYS" ] ; then
    install_readonly "$SSH_USER_AUTHORIZED_KEYS" "${R}/home/${USER_NAME}/.ssh/authorized_keys2"
  fi

  # Add SSH (v2) public key for user $USER_NAME
  if [ ! -z "$SSH_USER_PUB_KEY" ] ; then
    cat "$SSH_USER_PUB_KEY" >> "${R}/home/${USER_NAME}/.ssh/authorized_keys2"
  fi

  # Set permissions of $USER_NAME SSH authorized keys file
  if [ -f  "${R}/home/${USER_NAME}/.ssh/authorized_keys2" ] ; then
    chroot_exec chmod 600 "/home/${USER_NAME}/.ssh/authorized_keys2"
    chroot_exec chown ${USER_NAME}:${USER_NAME} "/home/${USER_NAME}/.ssh/authorized_keys2"

    # Allow SSH public key authentication
    sed -i "s|[#]*PubkeyAuthentication.*|PubkeyAuthentication yes|g" "${ETC_DIR}/ssh/sshd_config"
  fi

  # Limit the users that are allowed to login via SSH
  if [ "$SSH_LIMIT_USERS" = true ] ; then
    if [ "$ENABLE_ROOT" = true ] && [ "$SSH_ENABLE_ROOT" = true ] ; then
      echo "AllowUsers root ${USER_NAME}" >> "${ETC_DIR}/ssh/sshd_config"
    else
      echo "AllowUsers ${USER_NAME}" >> "${ETC_DIR}/ssh/sshd_config"
    fi
  fi

  # Disable password-based authentication
  if [ "$SSH_DISABLE_PASSWORD_AUTH" = true ] ; then
    if [ "$ENABLE_ROOT" = true ] && [ "$SSH_ENABLE_ROOT" = true ] ; then
      sed -i "s|[#]*PermitRootLogin.*|PermitRootLogin without-password|g" "${ETC_DIR}/ssh/sshd_config"
    fi

    sed -i "s|[#]*PasswordAuthentication.*|PasswordAuthentication no|g" "${ETC_DIR}/ssh/sshd_config"
    sed -i "s|[#]*ChallengeResponseAuthentication no.*|ChallengeResponseAuthentication no|g" "${ETC_DIR}/ssh/sshd_config"
    sed -i "s|[#]*UsePAM.*|UsePAM no|g" "${ETC_DIR}/ssh/sshd_config"
  fi
fi