Проектная работа по модулю
“SQL и получение данных” 
выполнила Харченко Татьяна

✓ В работе использовался локальный тип подключения postgresql.
✓ Использовался DBeaver в качестве программного обеспечения для решения согласно данного задания.

✓ Краткое описание БД - из каких таблиц и представлений состоит: 
● Таблицы:
aircrafts- Самолеты. Каждая модель воздушного судна 
идентифицируется своим трехзначным кодом (aircraft_code). 
Указывается также название модели (model) и максимальная 
дальность полета в километрах (range).

airports- Аэропорт идентифицируется трехбуквенным 
кодом (airport_code) и имеет свое имя (airport_name). 

boarding_passes - посадочный талон. Присваиваются 
последовательные номера (boarding_no) в порядке регистрации 
пассажиров на рейс (этот номер будет уникальным только в 
пределах данного рейса).

bookings - Бронирование идентифицируется номером 
(book_ref, шестизначная комбинация букв и цифр), может 
содержать несколько билетов и пассажирв.

flights- Рейс всегда соединяет две точки — аэропорты 
вылета (departure_airport) и прибытия (arrival_airport). Такое 
понятие, как «рейс с пересадками» отсутствует: если нет 
прямого рейса, в билет включаются несколько рейсов. 

seats - Каждое место определяется своим номером (seat_no) и 
имеет закрепленный за ним класс обслуживания (fare_conditions).

ticket_flights - Перелет соединяет билет с рейсом и 
идентифицируется их номерами.

tickets - Билет имеет уникальный номер (ticket_no), 
состоящий из 13 цифр, содержит идентификатор пассажира 
(passenger_id). Ни идентификатор пассажира, ни имя не 
являются постоянными (можно поменять паспорт, можно 
сменить фамилию), поэтому однозначно найти все билеты 
одного и того же пассажира невозможно.

● Представление:
flights_v - содержащее дополнительную информацию: 
• расшифровку данных об аэропорте вылета
• расшифровку данных об аэропорте прибытия
• местное время вылета 
• местное время прибытия
• продолжительность полета

● Материализованное представление:
routes - таблица рейсов содержит избыточность, 
информацию о маршруте (номер рейса, аэропорты 
отправления и назначения), которая не зависит от 
конкретных дат рейсов.

✓ Развернутый анализ БД - описание таблиц, логики, связей и бизнес области: 

● aircrafts:
✓ Каждая модель воздушного судна идентифицируется своим трехзначным кодом (aircraft_code)
✓ Индексы: PRIMARY KEY, btree (aircraft_code)
✓ Ограничения-проверки: CHECK (range > 0)
✓ Ссылки извне: TABLE "flights" FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) TABLE "seats" FOREIGN 
KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

● airports:
✓ Аэропорт идентифицируется трехбуквенным кодом (airport_code) и имеет свое имя (airport_name)
✓ Индексы: PRIMARY KEY, btree (airport_code)
✓ Ссылки извне: TABLE "flights" FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) TABLE "flights" FOREIGN 
KEY (departure_airport) REFERENCES airports(airport_code) 

● boarding_passes:
✓ Идентифицируется номером билета ( ticket_no ) и номером рейса ( flight_id)
✓ Индексы: PRIMARY KEY, btree (ticket_no, flight_id) UNIQUE CONSTRAINT, btree (flight_id, boarding_no) UNIQUE CONSTRAINT, 
btree (flight_id, seat_no) 
✓ Ограничения внешнего ключа: FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

● bookings:
✓ Идентифицируется номером (book_ref, шестизначная комбинация букв и цифр)
✓ Индексы: PRIMARY KEY, btree (book_ref)
✓ Ссылки извне: TABLE "tickets" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
 
● flights:
✓ Естественный ключ таблицы рейсов состоит из двух полей — номера рейса (flight_no) и даты отправления 
(scheduled_departure). 
✓ Статус рейса (status) может принимать одно из значений: Scheduled/OnTime/Delayed/Departed/Arrived/Cancelled
✓ Индексы: PRIMARY KEY, btree (flight_id) UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
✓ Ограничения-проверки: CHECK (scheduled_arrival > scheduled_departure) CHECK ((actual_arrival IS NULL) OR 
((actual_departure IS NOT NULL AND actual_arrival IS NOT NULL) AND (actual_arrival > actual_departure))) CHECK (status IN ('On 
Time', 'Delayed', 'Departed', 'Arrived', 'Scheduled', 'Cancelled'))
✓ Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) FOREIGN KEY 
(arrival_airport) REFERENCES airports(airport_code) FOREIGN KEY (departure_airport) REFERENCES airports(airport_code)
✓ Ссылки извне: TABLE "ticket_flights" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)

● seats:
✓ Идентифицируется своим номером (seat_no) и имеет закрепленный за ним класс обслуживания (fare_conditions): Economy, 
Comfort или Business. 
✓ Индексы: PRIMARY KEY, btree (aircraft_code, seat_no)
✓ Ограничения-проверки: CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))
✓ Ограничения внешнего ключа: FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE

● ticket_flights:
✓ Перелет соединяет билет с рейсом и идентифицируется их номерами
✓ Ограничения-проверки: CHECK (amount >= 0) CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))
✓ Ограничения внешнего ключа: FOREIGN KEY (flight_id) REFERENCES flights(flight_id) FOREIGN KEY (ticket_no) REFERENCES 
tickets(ticket_no)
✓ Ссылки извне: TABLE "boarding_passes" FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)

✓ Бизнес задачи, которые можно решить, используя БД:
Повышение рентабельности – одна из важнейших задач авиакомпании. Это позволяет 
определить пороговый уровень загрузки рейсов, при котором авиакомпания будет получать 
прибыль, выявлять резервы снижения себестоимости, определять наиболее рентабельные 
маршруты. 
● исходя из средней загруженности на рейсе по дням недели, оптимизировать распределение 
моделей самолетов по дальности полетов и количеству посадочных мест
● определить наименее востребованные направления, по количеству свободных мест на 
рейсе и оптимизировать количество рейсов по времени и дням, чтобы обеспечить 
максимальную загрузку. 
● используя данные распределения количества бронирований по диапазонам сумм, 
разработать стратегию развития и ценовой политики
● пользуясь данными о том как распределяются места разных классов в самолетах всех 
типов, разработать ценовую политику и оптимизировать распределения моделей 
самолетов по рейсам, исходя из спроса на определенный класс
● используя данные о среднем количестве свободных мест по времени рейса и частоте 
полетов, использовать системы скидок для стимулирования роста и заполнения пустых 
мест в самолете