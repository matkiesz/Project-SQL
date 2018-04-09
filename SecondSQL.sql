----------------------------------------------------------------------------------------------------
/* Dla ka¿dego wniosku podaj:miejsce docelowe podró¿y, miejsce wylotu podró¿y */

select * from szczegoly_podrozy;

--mam id wniosku w tabeli podrozy, nie musze robic join do wnioski
--sprawdze na poczatku tylko podroze z duza iloscia tras, aby sprawdzic czy firstvalue dziala poprawnie
select id_podrozy, count(1)
from szczegoly_podrozy
group by 1
having count(1) > 1
order by 2 desc;

-- sprawdz te dwa jako przyklady: 126400,127857
-- ktora date wziac po uwage: data wyjazdu czy data utworzenia?
-- najpierw wersja z data wyjazdu
select p.id_wniosku,
  s2.kod_wyjazdu, s2.kod_przyjazdu, data_wyjazdu,
  first_value(s2.kod_wyjazdu) over(partition by id_wniosku order by s2.data_wyjazdu) miejsce_wyjazdu,
  last_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_wyjazdu) miejsce_przyjazdu_zle,
  first_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_wyjazdu desc) miejsce_przyjazdu_ok
from podroze p
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.id_podrozy in (126400,127857)
order by 1,4;

-- teraz wersja z data utworzenia
select p.id_wniosku,
  s2.kod_wyjazdu, s2.kod_przyjazdu, data_wyjazdu, data_utworzenia,
  first_value(s2.kod_wyjazdu) over(partition by id_wniosku order by s2.data_utworzenia) miejsce_wyjazdu,
  last_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_utworzenia) miejsce_przyjazdu_zle,
  first_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_utworzenia desc) miejsce_przyjazdu_ok
from podroze p
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.id_podrozy in (126400,127857)
order by 1,5;

-- najlepsza kombinacja? Polaczenie daty wyjazdu i daty utworzenia!
select p.id_wniosku,
  s2.kod_wyjazdu, s2.kod_przyjazdu, data_wyjazdu, data_utworzenia,
  first_value(s2.kod_wyjazdu) over(partition by id_wniosku order by s2.data_wyjazdu) miejsce_wyjazdu_zle_sortowanie,
  first_value(s2.kod_wyjazdu) over(partition by id_wniosku order by s2.data_wyjazdu, s2.data_utworzenia) miejsce_wyjazdu_ok,

  first_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_wyjazdu desc) miejsce_przyjazdu_zle_sortowanie,
  first_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_wyjazdu desc, s2.data_utworzenia) miejsce_przyjazdu_ok
from podroze p
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.id_podrozy in (126400,127857)
order by 1,4,5;

-- do wysylki potrzebuje tylko id wniosku oraz miejca wyjazdu i przyjazdu. Oto finalna wersja do wysylki
select distinct p.id_wniosku,
  first_value(s2.kod_wyjazdu) over(partition by id_wniosku order by s2.data_wyjazdu, s2.data_utworzenia) miejsce_wyjazdu_ok,
  first_value(s2.kod_przyjazdu) over(PARTITION BY id_wniosku ORDER BY s2.data_wyjazdu desc, s2.data_utworzenia) miejsce_przyjazdu_ok
from podroze p
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.id_podrozy in (126400,127857)
order by 1;

----------------------------------------------------------------------------------------------------
/*Podstawowa predykcja z u¿yciem SQL: Chcê œledziæ ka¿dy dzieñ, widz¹c czy idziemy zgodnie z planem czy nie */

-- patrze jak sie ukladaja wnioski w czasie
select to_char(data_utworzenia, 'YYYY-MM-DD Day'), count(1)
from wnioski
group by 1
order by 1 desc;

-- biore tylko 3 ostatnie tygodnie
-- now daje dane od dzisiaj, wynik tylko 11 rekordow zamiast 21, gdzie reszta?
select to_char(data_utworzenia, 'YYYY-MM-DD Day'), count(1)
from wnioski
where data_utworzenia > now()-interval '3 weeks'
group by 1
order by 1 desc;

-- poprawne ostatnie 3 tyg
select to_char(data_utworzenia, 'YYYY-MM-DD Day'), count(1)
from wnioski
where data_utworzenia > '2018-02-09'::date-interval '3 weeks'+interval '1 day'
group by 1
order by 1 desc;

-- Kilka przykladow dat
select to_char(now(),'YYYY-MM-DD Day'),
  to_char(now()-interval '1 day','YYYY-MM-DD Day'),
  to_char(now()-interval '1 week','YYYY-MM-DD Day'),
  to_char(now()-interval '1 week'+interval '1 day','YYYY-MM-DD Day');

--jak wygenerowaæ wszystkie dni z lutego?
select
  generate_series(now(), '2018-02-28'::date + interval '1 day', '1 day');

-- jak wybrac ostatni dzien miesiaca?
select now(),
  date_trunc('month', now()) miesiac,
  date_trunc('year', now()) rok,
  date_trunc('day', now()) dzien,
  date_trunc('day', now()+interval '1 month') ten_sam_dzien_kolejny_miesiac,
  date_trunc('month', now()+interval '1 month') poczatek_kolejnego_miesiaca,
  date_trunc('month', now())+interval '1 month'-interval '1 day' ostatni_dzien_miesiaca;

-- jak jest data 3 tyg od 2018-02-09?
select '2018-02-09'::date - interval '3 weeks'+interval '1 day';

-- wracam do generowania sztucznych dat
with moje_daty as (select -- to jest odpowiedzialne za wygenerowanie dat z przyszlosci
  generate_series(
      date_trunc('day', '2018-01-20'::date), -- jaki jest pierwszy dzien generowania
      date_trunc('month', now())+interval '1 month'-interval '1 day', -- koncowy dzien generowania
      '1 day')::date as wygenerowana_data --interwa³, co ile dni/miesiecy/tygodni dodawac kolejne rekordy
  ),
aktualne_wnioski as ( -- to jest kawalek odpowiedzialny za aktualna liczba wnioskow
    select to_char(data_utworzenia, 'YYYY-MM-DD')::date data_wniosku, count(1) liczba_wnioskow
    from wnioski
    group by 1
  ),
lista_z_wnioskami as (
    select md.wygenerowana_data, -- dla danej daty
      coalesce(aw.liczba_wnioskow,0) liczba_wnioskow, -- powiedz ile bylo wnioskow w danym dniu, jesli byl NULL dodajemy coalesce
      sum(aw.liczba_wnioskow) over(order by md.wygenerowana_data) skumulowana_liczba_wnioskow -- laczna liczba wnioskow dzien po dniu
    from moje_daty md
    left join aktualne_wnioski aw on aw.data_wniosku = md.wygenerowana_data --left join dlatego, ze niektore dni nie maja jeszcze wnioskow. wlasnie dla nich bede robil predykcje
    order by 1),
statystyki_dnia as (
    select to_char(wygenerowana_data, 'Day') dzien, round(avg(liczba_wnioskow)) przew_liczba_wnioskow -- round aby nie uzupelniac liczbami zmiennoprzecinkowymi
    from lista_z_wnioskami
      where wygenerowana_data <= '2018-02-09'
    group by 1
    order by 1
    )
select lw.wygenerowana_data, liczba_wnioskow, przew_liczba_wnioskow,
  case
    when wygenerowana_data <= '2018-02-09' then liczba_wnioskow
    else przew_liczba_wnioskow end finalna_liczba_wnioskow, -- dodaje case aby wybrac realna liczbe albo przewidywana w zaleznosci od daty

  sum(case
    when wygenerowana_data <= '2018-02-09' then liczba_wnioskow
    else przew_liczba_wnioskow end) over(order by wygenerowana_data) skumulowana_z_predykcja -- dodaje funkcje okna aby zsumowac wartosci zarowo realne jak i predykcje
from lista_z_wnioskami lw
join statystyki_dnia sd on sd.dzien = to_char(lw.wygenerowana_data, 'Day')
;


----------------------------------------------------------------------------------------------------
1) Jaka data by³a 8 dni temu? - now - 8 days

select now() - interval '8 days'

----------------------------------------------------------------------------------------------------
2) Jaki dzieñ tygodnia by³ 3 miesi¹ce temu?     now -  3 months, DAY

select to_char ( now() - interval '3 months' , 'Day')

----------------------------------------------------------------------------------------------------
3) W którym tygodniu roku jest 01 stycznia 2017?      01.01.2017 week

select to_char ( '01.01.2017'::date , 'Week')

----------------------------------------------------------------------------------------------------
4) Podaj listê wniosków z w³aœciwym operatorem (który rzeczywiœcie przeprowadzi³ trasê) identyfikator_operatora (szczegoly_podrozy), id (wniosek)

select wnioski.id, identyfikator_operatora
 from wnioski
 join podroze p ON wnioski.id = p.id_wniosku
 join szczegoly_podrozy s2 ON p.id = s2.id_podrozy

----------------------------------------------------------------------------------------------------
5) Przygotuj listê klientów z dat¹ utworzenia ich pierwszego i drugiego wniosku. 3 kolumny: email, data 1wszego wniosku, data 2giego wniosku
email, data utworzenia (1st result), data utworzenia (2nd result)

select email, first_value(w.data_utworzenia) over(PARTITION BY k.email order by w.data_utworzenia asc) as First_result,  nth_value(w.data_utworzenia, 2) over(PARTITION BY k.email order by w.data_utworzenia asc) as Second_result
 from klienci k
 join wnioski w ON w.id = k.id_wniosku
 order by 1



KAMPANIE:
----------------------------------------------------------------------------------------------------
6)  kampaniê marketingow¹, która odbêdzie siê 26 lutego - przewidywana liczba wniosków z niej to 1000

with moje_daty as (select -- to jest odpowiedzialne za wygenerowanie dat z przyszlosci
  generate_series(
      date_trunc('day', '2018-01-20'::date), -- jaki jest pierwszy dzien generowania
      date_trunc('month', now())+interval '1 month'-interval '1 day', -- koncowy dzien generowania
      '1 day')::date as wygenerowana_data --interwa³, co ile dni/miesiecy/tygodni dodawac kolejne rekordy
  ),
  aktualne_wnioski as ( -- to jest kawalek odpowiedzialny za aktualna liczba wnioskow
    select to_char(data_utworzenia, 'YYYY-MM-DD')::date data_wniosku, count(1) liczba_wnioskow
    from wnioski
    group by 1
  ),

lista_z_wnioskami as (select md.wygenerowana_data, -- dla danej daty
  coalesce(aw.liczba_wnioskow,0) liczbawnioskow , -- powiedz ile bylo wnioskow w danym dniu
  sum(aw.liczba_wnioskow) over(order by md.wygenerowana_data) skumulowana_liczba_wnioskow -- laczna liczba wnioskow dzien po dniu
from moje_daty md
left join aktualne_wnioski aw on aw.data_wniosku = md.wygenerowana_data --left join dlatego, ze niektore dni nie maja jeszcze wnioskow. wlasnie dla nich bede robil predykcje
order by 1),

statystyki_dnia as (select to_char (wygenerowana_data, 'Day') dzien, round(avg(liczbawnioskow)) przew
  from lista_z_wnioskami
where wygenerowana_data <= '2018-02-09'
  group by 1
order by 1)

select lw.wygenerowana_data, liczbawnioskow, przew,
  case when wygenerowana_data <= '2018-02-09' then liczbawnioskow
  when wygenerowana_data = '2018-02-26' then 1000
   else przew end,

  sum(case when wygenerowana_data <= '2018-02-09' then liczbawnioskow
  when wygenerowana_data = '2018-02-26' then 1000
  else przew end) over (order by wygenerowana_data) skum_wyg

from lista_z_wnioskami lw
join statystyki_dnia sd on sd.dzien = to_char (lw.wygenerowana_data, 'Day');

----------------------------------------------------------------------------------------------------
7)  przymusow¹ przerwê serwisow¹, w sobotê 24 lutego nie bêdzie mo¿na utworzyæ ¿adnych wniosków

with moje_daty as (select -- to jest odpowiedzialne za wygenerowanie dat z przyszlosci
  generate_series(
      date_trunc('day', '2018-01-20'::date), -- jaki jest pierwszy dzien generowania
      date_trunc('month', now())+interval '1 month'-interval '1 day', -- koncowy dzien generowania
      '1 day')::date as wygenerowana_data --interwa³, co ile dni/miesiecy/tygodni dodawac kolejne rekordy
  ),
  aktualne_wnioski as ( -- to jest kawalek odpowiedzialny za aktualna liczba wnioskow
    select to_char(data_utworzenia, 'YYYY-MM-DD')::date data_wniosku, count(1) liczba_wnioskow
    from wnioski
    group by 1
  ),

lista_z_wnioskami as (select md.wygenerowana_data, -- dla danej daty
  coalesce(aw.liczba_wnioskow,0) liczbawnioskow , -- powiedz ile bylo wnioskow w danym dniu
  sum(aw.liczba_wnioskow) over(order by md.wygenerowana_data) skumulowana_liczba_wnioskow -- laczna liczba wnioskow dzien po dniu
from moje_daty md
left join aktualne_wnioski aw on aw.data_wniosku = md.wygenerowana_data --left join dlatego, ze niektore dni nie maja jeszcze wnioskow. wlasnie dla nich bede robil predykcje
order by 1),

statystyki_dnia as (select to_char (wygenerowana_data, 'Day') dzien, round(avg(liczbawnioskow)) przew
  from lista_z_wnioskami
where wygenerowana_data <= '2018-02-09'
  group by 1
order by 1)

  select lw.wygenerowana_data, liczbawnioskow, przew,

  case when wygenerowana_data <= '2018-02-09' then liczbawnioskow
  when wygenerowana_data = '2018-02-24' then 0
   else przew end,

  sum(case when wygenerowana_data <= '2018-02-09' then liczbawnioskow
  when wygenerowana_data = '2018-02-24' then 0
  else przew end) over (order by wygenerowana_data) skum_wyg

from lista_z_wnioskami lw
join statystyki_dnia sd on sd.dzien = to_char (lw.wygenerowana_data, 'Day');


----------------------------------------------------------------------------------------------------
8) Ile (liczbowo) wniosków zosta³o utworzonych poni¿ej mediany liczonej z czasu miêdzy lotem i wnioskiem?

with wnioski2 as (select wnioski.id as id, wnioski.data_utworzenia::date - data_wyjazdu::date as roznica
 from wnioski
 join podroze p ON wnioski.id = p.id_wniosku
 join szczegoly_podrozy s2 ON p.id = s2.id_podrozy)

 select percentile_cont(0.5) within group(order by roznica asc) as mediana,
  count(distinct case when roznica < 20 then id end) as licznawnioskowponizej20
  from wnioski2

----------------------------------------------------------------------------------------------------
9) Maj¹c czas od utworzenia wniosku do jego analizy przygotuj statystyke:

with czas as (select wnioski.id as wniosek, wnioski.data_utworzenia as data1, a.data_zakonczenia as data2, a.data_zakonczenia - wnioski.data_utworzenia,
extract(hours from a.data_zakonczenia - wnioski.data_utworzenia) as roznica
 from wnioski
 join analizy_wnioskow a ON wnioski.id = a.id_wniosku
order by roznica ASC )

select percentile_cont(0.5) within group(order by roznica asc) as mediana,
extract(hours from avg(data2 - data1)) as average,
 percentile_cont(0.75) within group(order by roznica asc) as P75,
 percentile_cont(0.25) within group(order by roznica asc) as P25,
  count(distinct case when roznica < 5 then wniosek end) as mniejnizP75,
  count(distinct case when roznica > -2 then wniosek end) as wiecejnizP25,
 count(distinct case when roznica != 0 then wniosek end) as rozne_od_mediany
 from czas




 --

with czas as (select wnioski.id as wniosek, wnioski.data_utworzenia as data1, a.data_zakonczenia as data2, a.data_zakonczenia - wnioski.data_utworzenia, extract(hours from a.data_zakonczenia -
wnioski.data_utworzenia) as roznica
 from wnioski
 join analizy_wnioskow a ON wnioski.id = a.id_wniosku
   WHERE stan_wniosku = 'wyplacony')


select percentile_cont(0.5) within group(order by roznica asc) as mediana,
extract(hours from avg(data2 - data1)) as average,
 percentile_cont(0.75) within group(order by roznica asc) as P75,
 percentile_cont(0.25) within group(order by roznica asc) as P25,
  count(distinct case when roznica < 0 then wniosek end) as mniejnizP75,
  count(distinct case when roznica > -4 then wniosek end) as wiecejnizP25,
 count(distinct case when roznica != -1 then wniosek end) as rozne_od_mediany

 from czas

 ---


with czas as (select wnioski.id as wniosek, wnioski.data_utworzenia as data1, a.data_zakonczenia as data2, a.data_zakonczenia - wnioski.data_utworzenia, extract(hours from a.data_zakonczenia -
wnioski.data_utworzenia) as roznica
 from wnioski
 join analizy_wnioskow a ON wnioski.id = a.id_wniosku
   WHERE stan_wniosku = 'odrzucony po analizie')


select percentile_cont(0.5) within group(order by roznica asc) as mediana,
extract(hours from avg(data2 - data1)) as average,
 percentile_cont(0.75) within group(order by roznica asc) as P75,
 percentile_cont(0.25) within group(order by roznica asc) as P25,
  count(distinct case when roznica < 17 then wniosek end) as mniejnizP75,
  count(distinct case when roznica > 1 then wniosek end) as wiecejnizP25,
  count(distinct case when roznica != 8 then wniosek end) as rozne_od_mediany

 from czas

----------------------------------------------------------------------------------------------------

10) Jakich jêzyków u¿ywaj¹ klienci? (kolumny: jezyk, liczba klientow, % klientow)
Jak czêsto klient zmienia jêzyk (przegl¹darki)? (kolumny: email, liczba zmian, czy ostatni jezyk wniosku zgadza sie z pierwszym jezykiem wniosku)


select w.jezyk, count(1),
  round(count(1) / sum(count(1)) over()::numeric, 4) procent
 from wnioski w
join klienci k  ON w.id = k.id_wniosku
group by 1


 select email, count(jezyk) over(partition by email) - 1 as ilezmianjezykow,
     first_value(jezyk) over(partition by email order by w.data_utworzenia asc) pierwszyjezyk,
    first_value(jezyk) over(partition by email order by w.data_utworzenia desc) ostatnijezyk
  from klienci k
   join wnioski w ON w.id = k.id_wniosku