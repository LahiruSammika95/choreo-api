import ballerina/http;

listener http:Listener httpListener = new (8080);

type Country record {|
    string code;
    string name;
    int population;
    string region;
    string incomeLevel;
    decimal caseFaitalityRatio;

|};

type CountryInfo record {

    string? iso3;
};

type covidCountry record {

    string country;
    int cases;
    int population;
    CountryInfo countryInfo;
    int deaths;

};

function getCovidCFR(string countryCode) returns Country|error {
    http:Client covidData = check new ("https://disease.sh/v3/covid-19/");
    covidCountry cdPayload = check covidData->get(string `countries/${countryCode}`);
    var {country: name, cases, population, deaths} = cdPayload;
    decimal caseFaitalityRatio = cfr(deaths, cases);
    http:Client worldBank = check new ("http://api.worldbank.org/v2/");
    xml wbPayload = check worldBank->get(string `country/${countryCode}`);
    var [incomeLevel, region] = extractWBData(wbPayload);

    return {code: countryCode, name, population, region, incomeLevel};
}

function cfr(int deaths, int cases) returns decimal => <decimal>deaths / <decimal>cases * 100;

function extractWBData(xml wbPayload) returns [string, string] {
    xmlns "http://www.worldbank.org" as wb;
    xml incomeLevelElement = wbPayload/**/<wb:incomeLevel>;
    xml regionElement = wbPayload/**/<wb:region>;
    return [incomeLevelElement.data(), regionElement.data()];
}

service / on httpListener {
    resource function get country/[string name]() returns Country|error {
        return getCovidCFR(name);
    }
}

function test() returns error? {

}
