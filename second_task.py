import argparse
import json
import logging
import os
import requests

from datetime import datetime, timedelta
from haversine import haversine, Unit


class FlightAgent:
	'''The FlightAgent helps to make requests to Kiwi.com's open API about flights.'''

	host = 'https://api.skypicker.com'
	location_url = host + '/locations'
	aggregation_url = host + '/aggregation_flights'

	def get_location_info(self, city):
		'''Returns information about the given city.'''

		url = f'{self.location_url}?term={city}'
		return self.make_request('get', url)

	def get_flights_info(self, fly_from, fly_to):
		'''Returns information about cheapest flights from the departure airport to the destination airport or airports'''

		dt1 = datetime.utcnow()
		dt2 = dt1 + timedelta(hours=24)
		date_from = dt1.strftime('%d/%m/%Y %H:%M')
		date_to = dt2.strftime('%d/%m/%Y %H:%M')
		url = (
			f'{self.aggregation_url}?fly_from={fly_from}&fly_to={fly_to}&'
			f'partner=picky&one_for_city=1&curr=USD&date_from={date_from}&date_to={date_to}'
		)
		return self.make_request('get', url)

	def make_request(self, method, url):
		'''Sends request to the given url'''

		params = {'url': url}

		try:
			response = getattr(requests, method)(**params)
		except requests.exceptions.ConnectionError as e:
			return None, e

		if response.status_code != 200:
			return None, 'Invalid Response from Server'
		response = response.json()
		return response


class FlightAggregator:
	'''The FlightAggregator class helps to find the best flight.'''

	def get_main_airports(self, departure, destinations):
		'''Returns main airports for the given departure and destination cities.'''

		agent = FlightAgent()
		departure_data, destination_data = agent.get_location_info(departure), {}

		for city in destinations:
			destination_data[city] = agent.get_location_info(city)

		departure_airports, destination_airports, city_names_by_ids = [], {}, {}
		departure_main_airport, destination_main_airports = None, {}

		if 'locations' in departure_data.keys() and len(departure_data['locations']) > 0:
			for i in departure_data['locations']:
				if i['type'] == 'airport':
					departure_airports.append(i)

		if len(departure_airports) > 0:
			departure_airports.sort(key=lambda x: x['rank'])
			departure_main_airport = departure_airports[0]

		if len(destination_data.items()) > 0:
			for k, v in destination_data.items():
				if 'locations' in v.keys() and len(v['locations']) > 0:
					for j in v['locations']:
						if j['type'] == 'airport':
							if k in destination_airports.keys():
								destination_airports[k].append(j)
							else:
								destination_airports[k] = [j]
						if j['type'] == 'city':
							city_names_by_ids[j['id']] = k

		if len(destination_airports.keys()) > 0:
			for k, v in destination_airports.items():
				if len(v) > 0:
					destination_airports[k].sort(key=lambda x: x['rank'])
					destination_main_airports[k] = destination_airports[k][0]
		return departure_main_airport, destination_main_airports, city_names_by_ids

	def get_best_flight(self, departure, destinations):
		'''Returns best destination city and price per km in USD.'''

		agent = FlightAgent()
		departure_main_airport, destination_main_airports, city_names_by_ids = self.get_main_airports(departure, destinations)
		destination_airport_codes = ','.join([v['code'] for k, v in destination_main_airports.items()])
		
		if not departure_main_airport:
			return None, 0

		data = agent.get_flights_info(departure_main_airport['code'], destination_airport_codes)
		prices_per_km = []

		if 'data' in data.keys() and len(data['data'].items()) > 0:
			for k, v in data['data'].items():
				start_point = (
					departure_main_airport['location']['lat'],
					departure_main_airport['location']['lon'],
				)
				city_name = city_names_by_ids.get(k)

				if city_name:
					end_point = (
						destination_main_airports[city_name]['location']['lat'],
						destination_main_airports[city_name]['location']['lon'],
					)
					flight_info = {
						'city': city_name,
						'price_per_km': self.get_price_per_km(v, start_point, end_point),
					}
					prices_per_km.append(flight_info)

		if len(prices_per_km) > 0:
			prices_per_km.sort(key=lambda x: x['price_per_km'])
			return prices_per_km[0]['city'], round(prices_per_km[0]['price_per_km'], 2)
		return None, 0

	def get_price_per_km(self, price, start_point, end_point):
		'''Calculates price per km in USD.'''

		distance = haversine(start_point, end_point)
		price_per_km = price / distance
		return price_per_km


if __name__ == '__main__':
	text = 'This is a program that finds the cheapest flights.'
	parser = argparse.ArgumentParser(description=text)
	parser.add_argument('--from', required=True, help='Set the departure city')
	parser.add_argument('--to', nargs='*', required=True, help='Set the list of potential destination cities')
	args = vars(parser.parse_args())
	departure = args.get('from')
	destinations = args.get('to')
	aggregator = FlightAggregator()
	best_flight_destination, price_per_km = aggregator.get_best_flight(departure, destinations)

	if best_flight_destination:
		print(f'The destination with the best flight is {best_flight_destination}.')
		print(f'The price of the flight is {price_per_km} dollars per kilometer.')
