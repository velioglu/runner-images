#!/bin/bash -xe

# Since standard Github runners have both runneradmin and runner users
# VMs of github runners are created with runneradmin user. Adding
# runner user and group with the same id and gid as the standard.
addgroup --gid 1001 runner
adduser --disabled-password --uid 1001 --gid 1001 --gecos '' runner
echo 'runner ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/98-runner

# runner unix user needed access to manipulate the Docker daemon.
# Default GitHub hosted runners have additional adm,systemd-journal groups.
usermod -a -G docker,adm,systemd-journal runner

# Some configuration files such as $PATH related to the user's home directory
# need to be changed. GitHub recommends to run post-generation scripts after
# initial boot.
# The important point, scripts use latest record at /etc/passwd as default user.
# So we need to run these scripts before bootstrap_rhizome to use runner user,
# instead of rhizome user.
# https://github.com/actions/runner-images/blob/main/docs/create-image-and-azure-resources.md#post-generation-scripts
sudo su -c "find /opt/post-generation -mindepth 1 -maxdepth 1 -type f -name '*.sh' -exec bash {} ';'"

# Post-generation scripts write some variables at /etc/environment file.
# We need to reload environment variables again.
source /etc/environment

# IMPORTANT NOTE: post-generation scripts use the latest entry
# in the /etc/passwd file, so we have to create other users after running them.

# Create runneradmin user so that cloudinit won’t waste time creating it
adduser --disabled-password --shell /bin/bash --gecos '' runneradmin
usermod -a -G sudo,adm,systemd-journal runneradmin

### Begin AWS only
echo "runneradmin ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/runneradmin
mkdir -p /home/runneradmin/.ssh
touch /home/runneradmin/.ssh/authorized_keys
chown -R runneradmin:runneradmin /home/runneradmin/.ssh
chmod 700 /home/runneradmin/.ssh
chmod 600 /home/runneradmin/.ssh/authorized_keys

# Add ubuntu user
useradd ubuntu --comment Ubuntu --groups adm,audio,cdrom,dialout,dip,floppy,lxd,netdev,plugdev,sudo,video --shell /bin/bash -m
### End AWS only


# We placed the script in the "/usr/local/share/" directory while generating
# the golden image. However, it needs to be moved to the home directory because
# the runner creates some configuration files at the script location. Since the
# github runner vm is created with the runneradmin user, directory is first moved
# to runneradmin user's home directory. At the end of this script, it will be moved
# to runner user's home folder. We are checking first whether actions-runner exists
# under "usr/local/share to make sure that the script can be run multiple times idempotently.

cp -R /usr/local/share/actions-runner ./
chown -R packer:packer actions-runner

# ./env.sh sets some variables for runner to run properly
./actions-runner/env.sh

# Include /etc/environment in the runneradmin environment to move it to the
# runner environment at the end of this script, it's otherwise ignored, and
# this omission has caused problems.
# See https://github.com/actions/runner/issues/1703
cat <<EOT > ./actions-runner/run-withenv.sh
#!/bin/bash
mapfile -t env </etc/environment
JIT_CONFIG="\$(cat ./actions-runner/.jit_token)"
exec env -- "\${env[@]}" ./actions-runner/run.sh --jitconfig "\$JIT_CONFIG"
EOT
chmod +x ./actions-runner/run-withenv.sh

# We take direct control over the unit file instead of relying on systemd-run's
# transient unit generation. It gives us more control over the unit file
# and avoids the issues with systemd-run's template expansion limits.
# https://github.com/ubicloud/ubicloud/commit/e2627b5c969ef013f06bf0584fb3b9aa9a07f94e
sudo tee /etc/systemd/system/runner-script.service <<'EOT'
[Unit]
Description=runner-script

[Service]
RemainAfterExit=yes
User=runner
Group=runner
WorkingDirectory=/home/runner
ExecStart=/home/runner/actions-runner/run-withenv.sh
EOT
sudo systemctl daemon-reload

# GitHub environment variables are only available in the workflow, not for unix
# user. We need some of these variables to run some features such as Ubicloud
# Cache. Runner script allows to run a hook script before the job starts and
# this hook has access to the environment variables. So we just persist them
# to a file and read them in the Ubicloud Cache proxy.
# See https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/running-scripts-before-or-after-a-job#triggering-the-scripts
cat <<EOT > ./actions-runner/start-hook.sh
#!/bin/sh
printenv | grep GITHUB | sudo tee /etc/.github_context >/dev/null || true
if [[ -f /home/runner/actions-runner/.ubicloud_start_message ]]; then
    cat /home/runner/actions-runner/.ubicloud_start_message
fi
EOT
chmod +x ./actions-runner/start-hook.sh

cat <<EOT > ./actions-runner/complete-hook.sh
#!/bin/sh
if [[ -f /home/runner/actions-runner/.ubicloud_complete_message ]]; then
    cat /home/runner/actions-runner/.ubicloud_complete_message
fi
EOT
chmod +x ./actions-runner/complete-hook.sh

echo "ACTIONS_RUNNER_HOOK_JOB_STARTED=/home/runner/actions-runner/start-hook.sh
ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/home/runner/actions-runner/complete-hook.sh" | sudo tee -a /etc/environment

# runner script doesn't use global $PATH variable by default. It gets path from
# secure_path at /etc/sudoers. Also script load .env file, so we are able to
# overwrite default path value of runner script with $PATH.
# https://github.com/microsoft/azure-pipelines-agent/issues/3461
echo "PATH=$PATH" >> ./actions-runner/.env

mv ./actions-runner /home/runner/

# Optimizes the runner process startup time
# https://github.com/actions/runner/blob/6ca97eeb88810dc898e04d53efcd80d8b24bc4e4/src/Runner.Listener/Runner.cs#L193
/home/runner/actions-runner/bin/Runner.Listener warmup && rm -rf /home/runner/actions-runner/_diag

chown -R runner:runner /home/runner/actions-runner
