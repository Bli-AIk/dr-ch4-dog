# 第 05 集：创建敌人、Encounter 与 ACT 菜单

欢迎回来——这是《从零做一个 Deltarune 同人游戏》系列的第 5 集，也是**第一章的第二集**。

第 04 集结尾的预告还记得吧？"下一集，把训练人偶换成真正的神烦狗"。对照第 03 集的目标清单，本集要给两行打勾：**敌人能出现在战斗里**和**ACT 菜单**。做完这两件事，"对手"和"互动"就都齐了——弹幕不着急，等下一集开始做。

## 素材：全部来自拆包

做敌人之前先解决素材。神烦狗（Annoying Dog）是 Deltarune 原作里的梗角色——就是那只时不时乱入的白狗。它的素材怎么来的？**全部来自拆包原作**，包括后面会用到的转圈（spin）动画。

拆包素材能用，但怎么用才合规，番外 EX02 已经把原则讲透了——出处要标、版权边界要守。详情请移步——去看看常见的素材源，以及对待这些素材应有的态度。

素材放哪？`assets/sprites/enemies/dog/`（第 02 集目录树里的素材目录，创一个狗自己的文件夹）。idle、bark、speak……动画帧都在里面。

## 从 dummy 到 dog：创建敌人

先坦白一个事实：本项目的狗敌人，第一版其实就是**复制 dummy.lua 改的**——EX01 结尾那句"第一遍抄"，你们还没开始抄——好吧，我自己先抄了（笑）。更有意思的是，我往回看我 git 历史里第一版，连本地化的 key 都没换，还在引用 dummy 的文本。抄完记得检查，别学我（笑）。

第 04 集我们认识了 actor——凡是"能演出的角色"都是它，`setActor("dummy")` 那句就是给敌人认领形象。现在轮到狗：`setActor("dog")` 认领的形象，定义在 `data/actors/dog.lua`。打开看看：

```lua
local actor, super = Class(Actor, "dog")

function actor:init()
    super.init(self)

    -- Display name (optional)
    -- 翻译一下：显示名（可选）
    self.name = "Annoying Dog"

    -- Match the largest frame in the dog animations (idle_2 is 22x19).
    -- 翻译：取狗动画里最大的一帧作为尺寸（idle_2 是 22x19）
    self.width = 22
    self.height = 19

    -- Path to this actor's sprites (defaults to "")
    -- 翻译：这个形象的贴图路径（默认为空）
    self.path = "enemies/dog"
    -- This actor's default sprite or animation, relative to the path (defaults to "")
    -- 翻译：默认动画（相对于贴图路径，默认为空）
    self.default = "idle"

    -- Table of sprite animations
    -- 翻译：动画表
    -- ["名字"] = { "贴图路径（动画自动根据文件名获取）", 帧间隔时间, 是否循环, 不循环播放完的下一个动画是什么 }
    self.animations = {
        ["idle"]  = { "idle/idle", 0.25, true },                      -- 待机
        ["speak"] = { "speak/", 1 / 6, true },                        -- 说话
        ["bark"]  = { "bark/", 1 / 6, false, next = "idle" },         -- 叫一声，播完回待机
        ["spin"]  = { "spin/spin", 1 / 30, false, next = "idle" },    -- 转圈，播完回待机
    }
end
```

actor 相关的文件都放到了 `data` 文件夹下，这说明其更偏向单纯的数据内容。而事实是——确实如此。

逐行看（翻译就写在注释下面一行）：`Class(Actor, "dog")`——**第二个参数就是它的 ID**；

然后看参数。`name` 是显示名；`width`/`height` 是尺寸（22×19，动画最大帧的尺寸）；

`path` 是贴图目录（`assets/sprites/` 下的 `enemies/dog`，素材节那个文件夹）；
`default` 是默认动画。

最下面的 `animations` 是动画目录——每个动画一行 `{ 帧序列, 每帧秒数, 是否循环 }`，还能写 `next`：播完自动切回哪个动画。素材节说"动画帧都在里面"，配上这张表，帧才真正被组织起来。（它还有几个动画——car、shock、sleep——留给后面集数，现在先认识这四个。）

现在再回来看敌人。`scripts/battle/enemies/dog.lua`：

```lua
local Dog, super = Class(EnemyBattler)

function Dog:init()
    super.init(self)
    self:applyLocalization()
    self:setActor("dog")

    self.max_health = 450
    self.health = 450
    self.attack = 4
    self.defense = 0
    self.money = 100
end
```

眼熟吗？第 04 集我们逐行看过 dummy.lua 的同款代码——`Class(EnemyBattler)` 继承、`init` 里设数值、`self` 挂属性。改动其实只有两处：类名 `Dummy` 变 `Dog`，`setActor("dummy")` 变 `setActor("dog")`。数值还是 450 血、4 攻——先抄着，后面想调可以自己调。

`setActor("dog")` 让敌人和形象对接——actor 文件里 `Class(Actor, "dog")` 注册的 ID 是 `"dog"`，这里按 ID 找的就是它。第 04 集说的"ID 是胶水"，又一次生效。（顺便一提：敌人的 ID 来自文件名，actor 的 ID 写在 `Class` 的第二个参数——两个机制，殊途同归。）

这里顺手把三个容易混的概念理清（三份文件都叫 dog，但职责不同）：

- **Actor（形象）**：`data/actors/dog.lua`——长什么样、动画怎么播（上面那段代码就是它）。
- **Enemy（敌人）**：`enemies/dog.lua`——数值和行为（血量、攻击、ACT 选项）；
- **Encounter（遭遇战）**：`encounters/dog.lua`——战斗的"载体"（敌人是谁、开场说什么、回合怎么流转——这是我们马上要创建的文件）；

（本集做完后，狗的"回合"还是借模板的弹幕（basic 那些）——你先别急着嫌"这弹幕不像狗"，第 06-08 集，三波弹幕挨个换成我们自己的。）

## 一个真正的 Encounter

敌人有了，得有个战斗把它装起来。`scripts/battle/encounters/dog.lua`：

```lua
local Dog, super = Class(Encounter)

function Dog:init()
    super.init(self)

    self.text = "{encounter_dog_start}"
    self.music = "dog_buster"
    self:addEnemy("dog")
end
```

三行配置，三件事：开场文本、战斗音乐、敌人名单。先看第一行——`self.text = "{encounter_dog_start}"`：**写文本，用 {key} 内联引用**——在写文本的位置上直接写 `{key}`，渲染时自动替换成当前语言的文本。这是最贴近 Kristal 原生写法的形式：原来这里就是直接写文本的，现在换成 {key}，翻译系统就接管了。

（`self.text` 虽然是个变量，但它的内容是"要显示的台词"，显示时照样走 `{key}` 解析。）

这时也许有人就要问了：那如果我写了某些东西，它们不支持 `{key}` 解析——我发现本地化失败了，这咋办？

那么用 `Game:loc("key")`——按当前语言，把语言文件里对应 key 的文本取回来，当成普通字符串用。本集后面 ACT 的名字，就是走这条路取的。

但无论如何，我建议你写代码时，先试试 `{key}` 写法，若不生效，再用 `Game:loc("key")` 顶替。

开场文本 `encounter_dog_start` 在语言文件里，中英各玩各的双关：

- 中文："* 你感觉你要吃点骨头了！"
- 英文："* You feel like you're going to have a bad bone."

音乐 `dog_buster` 是项目自带的曲子（`assets/music/dog_buster.ogg`）——它是别人做的曲子，我把它收进了项目，原曲视频原链：https://www.youtube.com/watch?v=NffMzWIkIn4 ，出处也记在项目 README 里。

最后是第 04 集留的悬念兑现：把 mod.json 的 `"encounter": "dummy"` 改成 `"encounter": "dog"`。启动——神烦狗站在战斗框右侧，看着你。

> 📷 此处插入截图：神烦狗出现在战斗中

## 初见钩子：骇入框架源码

在原动画，你可能注意到一件事：**苏西在待机时是开心的表情**——原作里苏西打绝大多数战斗时，可是阴着脸的。

这里用的是第二章的苏西笑脸待机动画（`battle/idle_happy`），我们把它借了过来。（素材还是拆包来的，只是换了个表情帧用。）

那这个效果怎么实现的？改引擎源码——就为了这么一个idle动画？？不至于——事实上，Kristal 有强大的 **hook（钩子）** 机制。

先说人话：hook 就是让你替换引擎自带内容，或在引擎自带内容上插入新内容的机制。它非常强大——理论上万物皆可换，万物皆可加。

引擎是别人写的代码，我们原则上不动它；hook 就是引擎留出来的"插口"——你写一段自己的代码"插"进去，引擎每次执行到对应位置时，先经过你的代码，由你决定自己处理——是在原引擎之前/之后执行一段新的逻辑，还是完全重写，亦或是……在某些条件下，叫回引擎原来的行为。

可以想象成你进不了后厨（不改引擎），但你能决定做什么饭。你在打饭窗口递了张条子（hook）——师傅每次打饭，都会先看一眼条子——然后按照你的安排走。

Kristal 里写 hook 的地方是 `scripts/hooks/` 目录——引擎自动加载，第 04 集"位置才重要"又生效了。不过先别急着看 hook——**先看引擎原本的 `setAnimation` 长什么样**，真实源码就这几行（`src/engine/game/battle/battler.lua`）：

```lua
function Battler:setAnimation(animation, callback)
    if not self.sprite then
        self:createSprite()
    end
    return self.sprite:setAnimation(animation, callback)
end
```

翻译一下：先确保角色身上的形象精灵存在，然后把动画描述交给精灵播放。再往里还有一层（`ActorSprite:setAnimation`，查 actor 动画表、按帧播放）——那段代码挺长，就不贴了，知道它"查表、播放"就够用；本集前面狗 actor 里那种 `animations` 表，就是给这一层用的。

现在再看我们的 hook——`scripts/hooks/PartyBattler.lua`：

```lua
---@class PartyBattler
local PartyBattler, super = HookSystem.hookScript(PartyBattler)

function PartyBattler:setAnimation(animation, callback)
    if animation == "battle/idle"
        and self.chara
        and self.chara.id == "susie"
        and Game.battle
        and Game.battle.encounter
        and Game.battle.encounter.id == "dog"
    then
        self.actor.offsets["battle/idle_happy"] = self.actor.offsets["battle/idle"] or { 0, 0 }
        animation = { "battle/idle_happy", 1 / 6, true }
    end

    return super.setAnimation(self, animation, callback)
end

return PartyBattler
```

逐行翻译：`HookSystem.hookScript(PartyBattler)`——"我要接管引擎的 PartyBattler 类"（PartyBattler 是战斗里角色形象的总管）。我们覆写它的 `setAnimation`（切换动画的方法）：**当且仅当**"苏西 + 待机动画 + 狗战斗"三个条件同时满足，就把动画描述换成 `battle/idle_happy`（1/6 秒每帧、循环）；其他情况原样放行——最后一行 `super.setAnimation`，调用的就是上面那段引擎源码。

严格说，这就是一个"在原机制**之前**插入新内容"的例子——看执行顺序：我们的代码先跑（检查条件、把动画描述换成笑脸版），**然后**才把改好的描述交给引擎原本的 `setAnimation` 执行。引擎原本的行为一个字没动，只是进来的参数被我们换过了。想在原机制**之后**插东西也简单：先调 `super`，再写你的代码——顺序反过来就行。

（也许有人会问：在之前改，那原行为不就被覆盖了吗？为什么原本的idle动画没有覆盖我们写的这个版本？——对，条件满足时确实覆盖了，但覆盖的不是你想的那样：原机制是"切到待机动画"，被我们变成"切到笑脸待机"。注意覆盖的是**参数**，不是引擎：`super.setAnimation` 照样执行，只是这次收到的参数是笑脸版。而且覆盖是精确的——三个条件缺一不可，苏西在别的战斗里照旧阴着脸，其他角色在狗战斗里也照旧。引擎一个字没动，行为按需改变，这就是 hook 的魔法所在。）

中间那行 offset 复制是技术细节：idle_happy 动画没有自己的偏移数据，所以我们需要把框架自带的idle的偏移抄一份给它，免得贴图位置对不上。

效果：苏西一见到狗就露出眼睛很高兴，其他战斗则依旧是阴郁苏大姐（草）。引擎源码一行没动——这就是"骇入框架源码"的正确姿势：**在插口上插手，而不是篡改引擎**。引擎要长期维护（第 01 集锁过版本），改引擎源码会留脏改动；hook 把改动收进项目自己的目录里，跟着项目走。

> 📷 此处插入截图：苏西在狗战斗中的开心待机

## ACT 菜单：抚摸与讲笑话

第 04 集试过 dummy 的 ACT（微笑、讲故事）——选项哪来的？先看 ACT 的名字和描述这些文本存在哪——语言文件。`lang/zh_hans.json`（`lang/en.json` 里是英文版，加 key 的流程和第 04 集一样）：

```json
"act_dog_pet": "抚摸",
"act_dog_pet_description": "前提是\n能碰到",
"act_dog_tell_joke": "讲笑话",
"act_dog_tell_joke_description": "或许有\n用？"
```

"前提是能碰到"，”或许有用“，是选择ACT时，右侧显示的灰色文本。

然后注册成 ACT——`registerAct` 是敌人的方法，加在敌人文件（`scripts/battle/enemies/dog.lua`）的 init 里，名字和描述的位置**直接写 {key}**。完整的样子是这样（就是前面那段 init，末尾加了三条注册）：

```lua
function Dog:init()
    super.init(self)
    self:applyLocalization()
    self:setActor("dog")

    self.max_health = 450
    self.health = 450
    self.attack = 4
    self.defense = 0
    self.money = 100

    -- 单人 ACT：谁都能用
    self:registerAct("{act_dog_pet}", "{act_dog_pet_description}")
    -- 队伍 ACT：苏西和利艾尔斯一起参与的摸狗 act
    self:registerAct("{act_dog_pet}", "{act_dog_pet_description}", {"susie", "ralsei"})
    -- 队伍 ACT：讲笑话，需要 100 TP
    self:registerAct("{act_dog_tell_joke}", "{act_dog_tell_joke_description}", {"susie", "ralsei"}, 100)
end
```

咦，这里也能写 {key}？——能。i18n 库在 `registerAct` 上挂了钩子（还记得初见钩子那节的 hook 吗？），注册时就把 `{key}` 解析成当前语言的文本了。所以不用先取出来存变量——**写的时候就直接写 {key}**，最省事。（init 第一行那个 `applyLocalization()` 是项目"运行中切换语言"的进阶做法，新手阶段先不用管它——照抄就行了。）

`registerAct` 的参数：名字、描述、需要的角色、所需 TP。

抚摸有单人版（谁都能摸）和队伍版（苏西、利艾尔斯一起摸）；讲笑话是队伍版，而且要 **100 TP** 才能用。

讲笑话的 TP 门槛值得单独说：原动画里笑话出现在战斗后半段（时间轴 1:00 左右）——那是动画做的演出安排。但如果是游戏，玩家一上来就讲笑话——呃，那可能三个回合还没放完就结束战斗了。

我们把它实现成硬性条件：攒够 100 TP 才能讲。**这是原动画没考虑到的，是我们补上的设计**——演出归演出，机制归机制，两者互相成就。

还有默认就有的"查看"（Check）——狗的 check 文本：

> 攻击 1 防御 1
> * 吸收了一件神器与某件物品！
> * 它体内有什么阻止你碰到它。

我们来写它吧。看这里的文本——语言文件里，讲笑话的台词是这些：

```json
"battle_dog_tell_joke_1": "* 大家一起想了一个烂双关笑话...[wait:5]",
"battle_dog_tell_joke_susie": "* 呃...[wait:5]\n* 为什么狗不能当歌手？",
"battle_dog_tell_joke_ralsei": "* 因为它会"汪"词！[wait:5][react:susie_reaction]",
"battle_dog_tell_joke_susie_reaction": "...",
"battle_dog_tell_joke_dog": "* 狗狗完全听不懂！",
"battle_dog_tell_joke_inside": "* 但它体内有什么对此很满意！",
"battle_dog_tell_joke_touch": "* 或许你可以碰到它了！"
```

你看，这有富文本：`[wait:5]` 是停顿半秒，`[react:susie_reaction]` 是让苏西冒出"……"的反应——这些标记嵌在翻译文本里，跟着语言走：翻译成别的语言，停顿和反应的位置纹丝不动。所以演出点跟着翻译走，而不是写死在代码里。（至于 `[sound:mus_rimshot]` 那个鼓点——它在代码里，等会儿的 cutscene 里你会看到它被拼在两句台词之间。）

## 讲笑话：一场小型演出

选了讲笑话，光弹一句文本太干——这是一场小型演出。`onAct` 里一句话启动：

```lua
local cutscene = Game.battle:startActCutscene("dog", "tell_joke")
```

`startActCutscene` 按 ID 找 `cutscenes/dog.lua` 里的演出函数（第 04 集说过：cutscene 是"战斗演出"）。演出内容的核心是几行 `cutscene:text`：

```lua
tell_joke = function(cutscene)
    cutscene:text("{battle_dog_tell_joke_1}")          -- 旁白

    cutscene:text(                                     -- 苏西的台词
        "{battle_dog_tell_joke_susie}",
        "nervous",                                     -- 表情
        "susie"                                        -- 立绘角色
    )
    ...
end
```

`cutscene:text(文本key, 表情, 角色)`——表情和角色指定谁在说话、什么表情；第一个参数写的是 `"{battle_dog_tell_joke_1}"`——**就是上面说的 {key} 内联引用**：台词渲染时自动替换成当前语言的文本，上面那段富文本里的停顿和反应，就藏在台词里。台词位置上的文本，全用这个写法。而第二个参数（`nervous`）和第三个参数（`susie`）是代码侧指定的——立绘和表情不走语言文件，走代码。

> 📷 此处插入截图：讲笑话演出（利艾尔斯说完，苏西一脸无语）

## 摸狗 MISS：文本里的方法调用

队伍版摸狗（三个人一起摸）的演出更有意思——它不走文件，直接内联一个"函数式 cutscene"：

```lua
Game.battle:startActCutscene(function(cutscene)
    cutscene:text("{act_dog_pet_party_text}", {
        functions = {
            dog_pet_miss = function()
                self:statusMessage("msg", "miss_gold")
            end
        }
    })
end)
```

对应的文本：

> * 大家一起去摸狗狗...[wait:5][func:dog_pet_miss][wait:1s]
> * 但是被它轻易地躲开了！

看到 `[func:dog_pet_miss]` 了吗？**文本播到这个地方时，会调用代码里 `functions` 表提供的同名函数**——在这里弹出一个金色的 MISS。文本和逻辑彻底分离：翻译随便改，演出点纹丝不动。这也是我们之后写所有"文本触发事件"的通用手法。

至于 MISS 为什么是金色的——下一节。

## FIGHT：金色 MISS

还记得第 02 集 API Reference 的例子吗——"想攻击敌人造不成伤害"？现在轮到我们亲手写。狗敌人加两个方法：

```lua
-- 狗闪避一切攻击，不吃任何伤害
function Dog:getAttackDamage(damage, battler, points)
    return 0
end

function Dog:hurt(amount, battler, on_defeat, color, show_status, attacked)
    local sprite = self:getActiveSprite()
    if not sprite or sprite.anim ~= "spin" then
        self:setAnimation("spin")
    end
    if show_status ~= false then
        self:statusMessage("msg", "miss_gold")
    end
end
```

`getAttackDamage` 返回 0——伤害计算出来直接归零，这是"打不死的狗"的数值层。第二层在 `hurt`（受伤时触发）：播放转圈（spin）动画 + 弹金色 MISS——原动画里那个标志性的"被打了转圈圈"演出。

（顺带交代：那个金色 MISS 贴图 `miss_gold` 不是拆包来的，是**我们自己改的**——引擎原版的 MISS 是白字（`assets/sprites/ui/battle/msg/miss.png`），我们照着做了一个金色版，放在同目录。素材不全是"拿来的"，也有这种"自己改一个"的活儿。）

数值上打不动，画面上闪得飞起——这正是原动画"打不死的狗"的完整还原。

> 📷 此处插入截图：攻击狗，金色 MISS

## MERCY：啥也别加了

最后，MERCY。说是"啥也别加"——其实有一处要**删**的东西。

模板的默认行为是这样的：**你直接对敌人用 MERCY，是会给敌人加饶恕值的**——这是引擎自带的机制：饶恕值没满时，每次 MERCY 都会按敌人的 `spare_points` 给它加一点（模板里是 20）。也就是说，光靠反复 MERCY，也能把饶恕值攒到满——攒满了就能饶恕它。

这可不是我们想要的：这只狗应该只有一条正确的饶恕路线（第 09 集才揭晓），而不是靠 MERCY 连按糊弄过去。所以把默认机制删掉——覆写 `onMercy`（引擎默认的"MERCY 处理"方法）：

```lua
-- 狗的饶恕值不吃 MERCY 直接加值这一套：接管 onMercy，什么都不做
function Dog:onMercy(battler)
    return false
end
```

引擎原版的 `onMercy` 逻辑是"没满就 +spare_points，满了就饶恕"；我们整个接管：什么都不做，返回 false（没饶成功）。从此 MERCY 按多少次都白按——狗现在彻底"饶不了咯"。

嗯，啥也别加了。做得很好。
## 检查本集成果

对照第 03 集清单：

- **敌人能出现在战斗里——打勾**：神烦狗站在战斗框右侧，待机动画播着；
- **ACT 菜单——打勾**：抚摸（单人/队伍）、讲笑话、查看，齐全。

链条也更新了一截：

```text
love . → 引擎加载 mod → mod.json 指定 encounter "dog" → encounters/dog.lua 说"敌人是 dog"
→ enemies/dog.lua 定义数值和 ACT → 战斗开始
```

和第 04 集相比，多出来的环节——敌人、遭遇战、ACT、钩子、演出——全是**我们亲手写的**了。弹幕还是模板的，那是下一集开始的主菜。

## 结尾

三件套齐了：对手（敌人）、舞台（Encounter）、互动（ACT 菜单）。但 Deltarune 战斗的魂——弹幕——还是借来的。下一集，第一回合："经典弹幕"。骨头架子，从右边飞过来。
