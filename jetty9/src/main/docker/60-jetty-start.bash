#!/bin/bash

# Configure the start command for the Jetty Container, executing a dry-run if
# necessary.

# If this is a jetty command
if expr "$*" : '^java .*/start\.jar.*$' >/dev/null ; then

  # check if it is a terminating command
  for A in "$@" ; do
    case $A in
      --add-to-start* |\
      --create-files |\
      --create-startd |\
      --download |\
      --dry-run |\
      --exec-print |\
      --help |\
      --info |\
      --list-all-modules |\
      --list-classpath |\
      --list-config |\
      --list-modules* |\
      --stop |\
      --update-ini |\
      --version |\
      -v )\
      # It is a terminating command, so exec directly
      exec "$@"
    esac
  done

  # Generate /jetty-start ?
  if [[ "$GENERATE_JETTY_START" == "TRUE" || ! -f /jetty-start || $(echo $@ | xargs) != "$(cat /jetty-start.args)" ]] ; then
    echo $@ > /jetty-start.args
    rm -f /jetty-start

    # Generate start command but remove -D arguments that are already in $JAVA_OPTS (which is mixed
    # in later by /docker-entrypoint.bash)
    for ARG in $($@ --dry-run --exec-properties=/jetty-start.properties | egrep '^[^ ]*java ' 2>/dev/null) ; do
      case $ARG in
        */java) echo java > /jetty-start ;;
        -D*)
          PROPERTY=$(expr "$ARG" : '\(-D[^=]*=\).*')
          [[ "$JAVA_OPTS" =~ ^.*$PROPERTY.*$ ]] || echo $ARG >> /jetty-start
          ;;
        *) echo $ARG >> /jetty-start ;;
      esac
    done
    [[ "$GENERATE_JETTY_START" == "TRUE" ]] && exit
  else
    echo $(date +'%Y-%m-%d %H:%M:%S.000'):INFO:docker-entrypoint:jetty start command from /jetty-start
  fi

  if [ $JETTY_BASE/start.d -nt /jetty-start ] ; then
    cat >&2 <<- 'EOWARN'
********************************************************************
WARNING: The $JETTY_BASE/start.d directory has been modified since
         the /jetty-start files was generated. Please either delete
         the /jetty-start file or re-run
         /scripts/jetty/generate-jetty-start.sh from a Dockerfile
********************************************************************
EOWARN
  fi
  set -- $(cat /jetty-start)
fi
