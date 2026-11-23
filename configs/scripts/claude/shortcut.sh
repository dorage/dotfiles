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
	local text model
	text=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$text" ]; then
		return 
	fi
	model=$(gum choose --header "모델을 골라라" "opus" "fable" )
	if [ -z "$model" ]; then
		return 
	fi
	claude --model "$model" --bg "$text"
}

function clbf() {
	local text
	text=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$text" ]; then
		return 
	fi
	claude --model fable --bg "$text"
}

function clbo() {
	local text
	text=$(gum write --placeholder "에이전트에게 시킬 프롬프트")
	if [ -z "$text" ]; then
		return 
	fi
	claude --model opus --bg "$text"
}
