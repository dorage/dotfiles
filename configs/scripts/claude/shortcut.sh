function cl() {
	claude
}

function cla() {
	claude agents
}

function cld() {
	claude --dangerously-skip-permissions
}

function clb() {
	prompt=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$prompt" ]; then
		return 
	fi
	model=$(gum choose --header "모델을 골라라" "opus" "fable" )
	if [ -z "$model" ]; then
		return 
	fi
	claude --model "$model" --bg "$prompt"
}

function clbf() {
	prompt=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$prompt" ]; then
		return 
	fi
	claude --model fable --bg "$prompt"
}

function clbo() {
	prompt=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$prompt" ]; then
		return 
	fi
	claude --model opus --bg "$prompt"
}
