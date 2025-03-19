# Калькулятор отношений на Lua

## Что такое Lua?
Lua - это интерпретируемый язак программирования, основной целью которого является высокая экспрессоивность при сохранении простоты синтаксиса. Lua зародился в 1993 году в Католическом университете Рио-де-Жанейро в Бразилии. С самого начала Lua задумывался как язык-связка, способный на высоком уровне вызывать конструкции написанные на других, более высокопроизводительных языках, в частности C.

Lua имеет очень легковесный интерптератор (интерпретатор языка вместе со стандартной библиотекой занимает около 220KiB), и хорошо интегрируется с C, что позволяет встраивать интерпретатор Lua в приложения для содания плагинов или добавления программатического контроля. Наиболее известными приложениями, использующими Lua таким образом являются Neovim, Adobe Lightroom, Roblox, Nmap, mpv и World of Warcraft.

## Калькулятор отношений
### DSL для задания отношений
В качестве DSL для регистрации отношений мы решили использовать сам Lua. Для регистрации отношения пользователю необходимо вызвать функцию `register_relations`, которая принимает на вход название отношения и таблицу, содержащую последовательность отношений которые необходимо пройти в обратном порядке чтобы достичь этот тип родственника. Пример: `register_relations("grandmother", {"female", "parent", "parent"})`. Итоговая последовательность отношений таким образом напоминает естественные предложения на английском языке, если поместить предлог "of" перед каждым отношением, не являющимся фильтром по полу. A grandmother is a female parent of the parent. Программой предопределены отношения parent, child, spouse, а также фильтры male и female. Также самым последним отношением по умолчанию является фильтрация элемента, для которого вызывается цепочка отношений. Таким образом, ни один человек не является сам себе братом или каким-либо другим родственником.

Поскольку пользователь имеет доступ ко всем конструкциям языка (за исключением доступа к библиотекам), он может задавать отношения программатически:
```lua
local relation = {"parent", "parent"}
local relation_name = "grandparent"
local order_prefix = "great"

for i=1,11 do
	register_relations(relation_name, relation)
	relation[#relation+1] = "parent"
	relation_name = order_prefix .. relation_name
end
```
Данный пример задёт прародителей до 10го колена.
### Поиск отношений для заданного человека
Поиск людей, имеющих то или иное отношение к рассматриваемому человеку реализован при помощи DFS, написанного при помощи замыканий. Для понимания решения, сначала необходимо объяснить, что такое итераторы в Lua. Итератор - это функция, которая на каждом вызове возвращает следующее значение из некоторого списка. Сами итераторы создаются при помощи фабрик итераторов. Пример:
```lua
function values (table)
	local i = 0
	return function () i = i + 1; return t[i] end
end
```
Данная функция создаёт итератор по числовым ключам для заданной таблицы.

Наше решение построено поверх таких итераторов: для каждого человека предопределены фабрики итераторов по детям, родителям и супругу/супруге. Также у каждого человека есть фильтр по полу, который также реализован при помощи итераторов. Таким образом, поскольку отношения задаются композицией, у нас получается цепочка из итераторов. Для поиска людей, имеющих отношение к рассматриваемому человеку, мы итерируемся по людям, состоящим в последнем указанном в списке отношении к рассматриваемому человеку. Для каждого из них мы ищем людей, состоящих в отношении, которое идёт вторым с конца, и т.д.
### Чтение данных о людях
TODO
### Интерактивный промпт
TODO
