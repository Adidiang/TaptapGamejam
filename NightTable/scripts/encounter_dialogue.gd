class_name EncounterDialogue
extends RefCounted
## Replace these placeholder lines or provide a Texture2D in a line's "portrait" field.
static func for_room(room: Dictionary) -> Array:
	if room.kind=="shop":
		return [
			{"speaker":"行商","text":"进来看看吧。前面的路不好走，总得带些用得上的东西。"},
			{"speaker":"行商","text":"卡牌和遗物都在这里，价格用质押点结算。挑好再决定，不必着急。"},
			{"speaker":"行商","text":"那么，看看今天有什么适合你。"},
		]
	if room.kind=="event":
		if room.get("title","")=="无名祭坛":
			return [
				{"speaker":"无名的声音","text":"钟声终于传到这里了。你已经走过了那扇铜门。"},
				{"speaker":"无名的声音","text":"这枚印记会让你的负荷上限降低一点，却也能替你记住一个名字。"},
				{"speaker":"无名的声音","text":"是否带走它，由你决定。"},
			]
		var gift: String = {"铜钥匣":"这把铜钥能打开旁边的铜锁。拿到之后，靠近那扇门试试看。","钟机房":"把这枚齿轮带上，再启动房里的钟机。它会为你打开一条隐藏的路。"}.get(room.get("title",""),"这里有些留下来的东西。看看有没有你用得上的，愿意的话就带走吧。")
		return [
			{"speaker":"留守者","text":"别紧张，这个房间不用打牌。你可以在这里歇一会儿。"},
			{"speaker":"留守者","text":gift},
			{"speaker":"留守者","text":"做出选择后，再继续往前走吧。"},
		]
	if room.kind=="boss":
		return [
			{"speaker":"女皇","text":"你终于走到了这里。那些关上的门，还在你身后。"},
			{"speaker":"女皇","text":"这次没有下一间了。你带来的每一张牌，都会留下答案。"},
			{"speaker":"女皇","text":"坐下吧。让我们打完最后一局。"},
		]
	return [
		{"speaker":"守夜人","text":"门已经关上了。别急，这间屋子只留你片刻。"},
		{"speaker":"守夜人","text":"桌上的牌会记住你的选择。想再拿一张，还是就此停下？"},
		{"speaker":"守夜人","text":"等这一局结束，门自然会打开。来吧，轮到你了。"},
	]
