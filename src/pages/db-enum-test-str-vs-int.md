<!DOCTYPE html>
<html lang=ru>
<head>
    <meta charset="UTF-8">
    <title>Сравнение скорости баз данных с численными и строковыми перечислениями - Темотин шкафчик</title>
    <link rel="stylesheet" type="text/css" href="/boorish.css">
    <!--# include virtual="/include/ga.html" -->
</head>
<body>
<!--# include virtual="/header.html" -->
<div id=page>
<div id=content class=content>
	<div class="nav"><a href="/">На главную</a></div>

<h1>Сравнение скорости баз данных с численными и строковыми перечислениями</h1>

<h2>Посыл</h2>
<p>В мае сего года, Александр Кошелев написал <a href="http://webnewage.org/post/2008/5/12/perechisleniya-na-sluzhbe-dobra/">как сделать перечисления в джанге</a>. И большое ему за это спасибо. Но. Александр выступает за читабельную raw базу, а я против. Вот, что он пишет:</p>
<blockquote>
<p>Потом, что будет если вы просмотрите raw базу? Увидите там кучу строк, где в поле "тип" какие-то не понятные числа</p>
<p>надо использовать строковые литералы для обозначения типа и сменить тип поля в модели на CharField. И пускай это чуть-чуть менее эффективно с точки зрения объема информации.</p>
</blockquote>
<p>Уважаемый Александр! Насрать на размер базы! Не в этом дело.</p>
<p>О том, почему <strong>в базе должны храниться чиселки-айдишники вместо строк</strong>, там где это можно, низлежащий тест на скорость.</p>
<h2>Тест на скорость</h2>
<p>Для теста использовалась табличка примерно такой структуры:
<table><thead><tr><th>имя</th><th>тип поля</th><th>индекс</th></tr></thead>
<tbody>
    <tr><td>id</td><td>int</td><td>PK</td></tr>
    <tr><td>name</td><td>varchar(100)</td><td>-</td></tr>
    <tr><td>pass</td><td>varchar(50)</td><td>-</td></tr>
    <tr><td>email</td><td>varchar(100)</td><td>-</td></tr>
    <tr><td>atype</td><td><strong>int</strong> и <strong>varchar(30)</strong></td><td>index</td></tr>
    <tr><td>i1</td><td>float</td><td>-</td></tr>
</tbody></table></p>
<p>Табличка заполнялась примерно 2 миллионами записей, в которых все поля - случайные слова. Для atype int использовалось 7 цифр, для atype str - около 40 слов.</p>
<p>Тест производился на двух СУБД: SQLite 3.4 и Postgres 8.3. Нужно будет еще найти время, провести его на MySQL, конечно.</p>
<p>Суть теста грубо неумелая: выбрать всех юзеров where atype = каждое возможное его значение и выбрать всех юзеров group by atype.</p>
<p>Запросы:</p>
<p><code>SELECT COUNT(*) FROM tt WHERE atype=x;</code><br>
<code>SELECT COUNT(*) FROM tt GROUP BY atype;</code></p>
<table class="width-50pc center-inner-td f-left"><thead><caption>atype integer</caption>
<tr><th>кто</th><th>where</th><th>group</th></thead>
<tbody>
    <tr><td>SQLite</td><td>0.549</td><td>6.119</td></tr>
    <tr><td>Postgres</td><td>3.138</td><td>1.371</td></tr>
</tbody></table>
<table class="width-50pc center-inner-td f-right"><thead><caption>atype string</caption>
    <tr><th>кто</th><th>where</th><th>group</th></thead>
<tbody>
    <tr><td>SQlite</td><td>0.779 (+41%)</td><td>9.532 (+55%)</td></tr>
    <tr><td>Postgres</td><td>14.698 (+368%) o_O</td><td>1.469 (+7%)</td></tr>
</tbody></table>

<div class="clearer">&nbsp;</div>

<h2>Выводы</h2>
<p>Да, всё грубо, приближенно, можно натюнить на совсем другие числа, но.</p>
<p>Если мы говорим о типах юзеров, статусах заказов, совершенно точно быстрее будет численное перечисление.</p>
<p>Если речь идёт о какой-то таблице, в которой редко работают с одной записью, но чаще сразу со всей группой перечисления, то вам лучше не использовать SQLite :). А если записей немного (в пределах миллиона), то можно и строки, чёрт с вами.</p>
<p>Я за числа везде и всегда. <strong>SQL, как и XML &mdash; не для людей</strong>. :)</p>

</div>
</div>
<!--# include virtual="/include/gadsense.html" -->
<!--# include virtual="/footer.html" -->
</body>
</html>
