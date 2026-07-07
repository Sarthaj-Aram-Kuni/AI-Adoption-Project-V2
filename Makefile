.PHONY: collect features analyse all test

collect:
	python -m src.data_collection.companies_house
	python -m src.data_collection.website_finder
	python -m src.data_collection.scraper
	python -m src.data_collection.geography

features:
	python -m src.features.ai_keywords
	python -m src.features.paragraph_classifier
	python -m src.features.network
	python -m src.features.proximity
	python -m src.features.build_dataset

analyse:
	python -m src.analysis.descriptives
	python -m src.analysis.models
	python -m src.analysis.robustness
	python -m src.visualization.interaction_plots

all: collect features analyse

test:
	pytest -q
