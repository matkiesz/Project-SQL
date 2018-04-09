-- SKRYPT SQL - ZESTAW PRZYKLADOWYCH ZAPYTAN

-- 1) ntile - dzieli zestaw liczba na takie same N grup i przyporządkowuje każdej liczbie w której grupie się znajdą
select distinct val,
  ntile(6) over(order by val asc) nt_6,
  ntile(2) over(order by val asc) nt_2,
  ntile(10) over(order by val asc) nt_10,
  ntile(100) over(order by val asc) nt_100
from (
  select 111 as val
  union ALL
  select 2
  union ALL
  select 7
  union ALL
  select 8
  union ALL
  select 11
  union ALL
  select 1 ) subq;


-- 2) rank VS dense_rank - rank zwraca pozycje w rankingu liczb, te same liczby moga otrzymac ten sam rank. Maksymalny rank bedzie calkowita liczba wystapien
-- dense_rank nadaje ranking na podstawie tylko rekordow, nie uwzgledniajac ile razy dana liczba wystepuje w zbiorze
-- percent_rank relatywna pozycja liczby w rankingu, wyrazona w procentach, ostatni rekord otrzyma 100%
select distinct kwota_rekompensaty,
  rank() over(order by kwota_rekompensaty) rank,
  dense_rank() over(order by kwota_rekompensaty) dense_rank,
  percent_rank() over(order by kwota_rekompensaty) percent_rank
  from wnioski
order by 1;

-- 3) nth_value
-- nth - nta wartość z posortowanego zbioru
select distinct nth_value(kwota_rekompensaty, 100) over(order by kwota_rekompensaty), --100 wartosc ze zbioru
  nth_value(kwota_rekompensaty, 10000) over(order by kwota_rekompensaty), --10000 wartosc ze zbioru
  nth_value(kwota_rekompensaty, 100000) over(order by kwota_rekompensaty) --100000 wartosc ze zbioru
from wnioski;

-- 4) coalesce(kol1, kol2) - zwraca pierwsza nienullowa wartosc
-- lista podrozy gdzie operator ktory sprzedal bilet, operowal trasą
SELECT id_podrozy,
  coalesce(sp.identyfikator_operator_operujacego, sp.identyfikator_operatora) operator_wlasciwy
from szczegoly_podrozy sp
where sp.identyfikator_operatora = sp.identyfikator_operator_operujacego or sp.identyfikator_operator_operujacego is null;

-- 5) date trunc
select id, data_utworzenia, date_trunc('day', data_utworzenia) dzien,
  date_trunc('month', data_utworzenia) miesiac,
  date_trunc('quarter', data_utworzenia) kwartal,
  date_trunc('year', data_utworzenia) rok
from wnioski;

-- 6) daterange - podaje przedzial miedzy dwiema datami
select id, data_utworzenia::date, data_zakonczenia::date, daterange(data_utworzenia::date, data_zakonczenia::date)
from analizy_wnioskow
where data_zakonczenia::date > data_utworzenia::date;

-- 7) Backlogi - jakie są zalegości w przetwarzaniu wnioskow?
SELECT to_char(w.data_utworzenia, 'YYYY-MM-DD') dzien,
  count(distinct case when aw.id is null then w.id end) as liczba_nierozpoczetych,
  sum(count(distinct case when aw.id is null then w.id end)) over (order by to_char(w.data_utworzenia, 'YYYY-MM-DD')) skumulowana_nierozpoczete,
  count(distinct case when aw.id is not null and aw.data_zakonczenia is null then w.id end) as liczba_niezakonczonych,
  sum(count(distinct case when aw.id is not null and aw.data_zakonczenia is null then w.id end)) over (order by to_char(w.data_utworzenia, 'YYYY-MM-DD')) skumulowane_niezakonczone
  FROM
  wnioski w
  LEFT JOIN analizy_wnioskow aw on aw.id_wniosku = w.id
WHERE w.stan_wniosku = 'nowy'
group by 1
order by 1;

-- 8) jakie są liczby przetwarzanych wnioskow i casy do akceptacji / odrzucenia ich?
select to_char(w.data_utworzenia, 'YYYY-MM-DD') dzien_utworzenia_wnioskuews,
  count(1) wnioski,
  count(distinct case when aw.data_zakonczenia is null then w.id end) "Not completed",
  extract(days from avg((case when aw.status = 'zaakceptowany' then aw.data_zakonczenia - w.data_utworzenia end)::interval)) "Days to accepted",
  extract(days from avg((case when aw.status = 'odrzucony' then aw.data_zakonczenia - w.data_utworzenia end)::interval)) "Days to rejected"
from wnioski w
left join analizy_wnioskow aw ON w.id = aw.id_wniosku
group by 1
order by 1;


-- 9) jakie są statusy analizy wnioskow, biorac pod uwage niezakonoczony i nierozpoczete?
select
case
when aw.status = 'zaakceptowany' then '1) zaakceptowany'
when aw.status = 'odrzucony' then '2) odrzucony'
when aw.id is null then '3) nierozpoczety'
when aw.id is not null and aw.data_zakonczenia is null then '4) niezakonczony'
end status, count(1), count(1)/sum(count(1)) over()::numeric pct,
  id_agenta
from wnioski w
  left join analizy_wnioskow aw ON w.id = aw.id_wniosku
group by 1,2;

-- 10) jaki jest % akceptacji dla kazdego operatora?
select coalesce(s2.identyfikator_operator_operujacego, s2.identyfikator_operatora),
  count(distinct w.id) liczba_wnioskow,
  count(distinct case when ao.status_odp = 'zaakceptowany' then w.id end) liczba_wnioskow_zaakceptowanych,
  count(distinct case when ao.status_odp = 'zaakceptowany' then w.id end)/count(distinct w.id)::numeric proc_zaakceptowanych
from wnioski w
left join analiza_operatora ao on ao.id_wniosku = w.id
join podroze p ON w.id = p.id_wniosku
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.czy_zaklocony = true
group by 1
order by 4 desc;

-- 11) Co stalo sie z odrzuconymi nieslusznie wnioskami przez operatora?
select distinct status_odp from analiza_operatora;

select w.stan_wniosku, count(1)
from wnioski w
join analiza_operatora ao on ao.id_wniosku = w.id
where ao.status_odp = 'odrzucony nieslusznie'
group by 1
order by 2 desc;


-- 12) Czy wnioski odrzucane nieslusznie przez operatora sa takze odrzucane przez dial prawny?
select ap.status, count(1)
from wnioski w
join analiza_operatora ao on ao.id_wniosku = w.id
join analiza_prawna ap on ap.id_wniosku = w.id
where ao.status_odp = 'odrzucony nieslusznie'
group by 1
order by 2 desc;

-- 13) statystyki operatorow
select coalesce(s2.identyfikator_operator_operujacego, s2.identyfikator_operatora),
  count(distinct w.id) liczba_wnioskow,
  count(distinct case when ao.data_odpowiedzi is not null then w.id end) liczba_odpowiedzi,
  count(distinct case when ao.status_odp = 'zaakceptowany' then w.id end) liczba_wnioskow_zaakceptowanych,
  count(distinct case when ao.status_odp = 'odrzucony nieslusznie' then w.id end) liczba_wnioskow_odrzuconych_nieslusznie,
  count(distinct case when ao.status_odp = 'odrzucony slusznie' then w.id end) liczba_wnioskow_odrzuconych_slusznie,
  avg(extract(days from ao.data_odpowiedzi - w.data_utworzenia)) sredni_czas_odpowiedzi_od_wniosku,
  avg(extract(days from ao.data_odpowiedzi - aw.data_zakonczenia)) sredni_czas_odpowiedzi_od_wyslania
from wnioski w
left join analizy_wnioskow aw on aw.id_wniosku = w.id
left join analiza_operatora ao on ao.id_wniosku = w.id
left join analiza_prawna ap on ap.id_wniosku = w.id
join podroze p ON w.id = p.id_wniosku
join szczegoly_podrozy s2 ON p.id = s2.id_podrozy
where s2.czy_zaklocony = true
group by 1
order by 4 desc;

-- 14) Jakich dokumentow zadamy najczesciej i jakie otrzymujemy?
select typ_dokumentu, count(1), avg(extract(days from data_otrzymania - data_wyslania))
from dokumenty
group by 1
order by 2 desc;

-- 15) ktorzy agenci bardzo mocno spowalniaja proces otrzymywania dokumentow?
with stat_agentow as (
  select agent_id, avg(extract(days from data_otrzymania - data_wyslania)) czas_do_otrzymania
  from dokumenty d
  group by 1
  order by 2 desc
), p_95_q as (
  select percentile_cont(0.90) within group(order by czas_do_otrzymania) p90 from stat_agentow
)
select *
from stat_agentow
join p_95_q on 1=1
where czas_do_otrzymania > p90;



