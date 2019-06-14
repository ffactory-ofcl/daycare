if ! tmux ls | grep -sq daycare; then
    tmux -2u new-session -d -s "daycare" -n "flask" "source env/bin/activate && systemctl start mongod && while true; do run/Flask.sh; echo; read -p \" >> Enter to restart! (Ctrl+C to quit)\"; done;"
    tmux new-window -t "daycare" -n "elm" "run/Elm.sh; read -p \">>Press enter to leave\""
    tmux new-window -t "daycare" -n "stop" "echo Ctrl+b d to detach; read -p \">>Press enter to quit\"; run/Stop.sh"
fi
tmux att -t "daycare"