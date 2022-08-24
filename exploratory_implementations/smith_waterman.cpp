#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <tuple>
#include <algorithm>
#include <iomanip>

using namespace std;

std::string parseFasta(std::string filename) {
	std::ifstream referenceFile(filename);
	std::string temp, reference;
	std::getline(referenceFile, temp);
	while (std::getline(referenceFile, temp))
		reference += temp;
	
	return reference;
}


class DPAligner {
public:
	DPAligner(const std::string& reference, const std::string& query) : _reference(reference), _query(query), _n(query.size() + 1), m(reference.size() + 1), _maxScore(0) {}
	
	void printDPTable(int *DPTable);
	
	void smithWaterman();
	
	// Dynamic Gap Selector Smith Waterman
	void dgsSW();
	
	void compressCigarString() {
		std::reverse(_uncompressedCigarString.begin(), _uncompressedCigarString.end());
		int index = 0;
		while (index < _uncompressedCigarString.size()) {
			char currentOp = _uncompressedCigarString[index];
			int opCounter = 0;
			
			while (index < _uncompressedCigarString.size() && currentOp == _uncompressedCigarString[index]) {
				opCounter++; 
				index++;
			}
			
			_cigarString += std::to_string(opCounter);
			_cigarString += currentOp;
		}
	}
	
	void print() {		
		std::cout << "Alignment score: " << _maxScore << std::endl;
		std::cout << "Start pos: " << _startPosition + 1 << std::endl;
		std::cout << "Cigar: " << _cigarString << std::endl;
	};
	
private:
	inline size_t get(int i, int j) {
		return i * m + j;
	}
	
	const std::string _reference, _query;
	const int _n, m;
	
	int _maxScore, _startPosition;
	vector<char> _uncompressedCigarString;
	std::string _cigarString;
	
	const int MATCH_PENALTY = 2;
	const int SNP_PENALTY = -1;
	const int GAP_OPENING_PENALTY = -2;
	const int GAP_PENALTY = -2;	
};

void DPAligner::printDPTable(int *DPTable) {
	for (int i = 0; i < _n; i++) {
		for (int j = 0; j < m; j++) {
			std::cout << std::setw(2) << std::setfill('0') << DPTable[i * m + j] << ' ';
		}
		std::cout << std::endl;
	}
}

void DPAligner::smithWaterman() {
	// Calculate DP Table
	int *DPTable = (int *)calloc(_n * m, sizeof(int));
		
	pair<int,int> maxScoreIndex = {0, 0};
	for (int i = 1; i < _n; i++)
		for (int j = 1; j < m; j++) {
			if (_reference[j - 1] == _query[i - 1])
				DPTable[get(i, j)] = DPTable[get(i - 1, j - 1)] + MATCH_PENALTY;
			else
				DPTable[get(i, j)] = std::max(
					std::max(DPTable[get(i - 1, j)], DPTable[get(i, j - 1)]) + GAP_PENALTY,
					std::max(DPTable[get(i - 1, j - 1)] + SNP_PENALTY, 0)
				);
			
			if (DPTable[get(i, j)] > _maxScore)
				std::tie(_maxScore, maxScoreIndex) = std::pair{DPTable[get(i, j)], std::pair{i, j}};
		}
	
	// Backtrack result	
	int i, j;
	std::tie(i, j) = maxScoreIndex;
	while (DPTable[get(i, j)] > 0) {
		int currentScore = DPTable[get(i, j)];
		int snpScore = DPTable[get(i - 1, j - 1)];
		int deletionScore = DPTable[get(i, j - 1)];
		int insertionScore = DPTable[get(i - 1, j)];
		
		char cigarCharacter;
		std::tie(cigarCharacter, i, j) = [&]() -> std::tuple<char, int, int> {
			if (currentScore == snpScore + MATCH_PENALTY && _reference[j - 1] == _query[i - 1])
				return {'M', i - 1, j - 1};
			else if (currentScore == snpScore + SNP_PENALTY)
				return {'S', i - 1, j - 1};
			else if (currentScore == deletionScore + GAP_PENALTY)
				return {'D', i, j - 1};
			else if (currentScore == insertionScore + GAP_PENALTY)
				return {'I', i - 1, j};
			else
				throw std::runtime_error("Cannot match according DP score during backtrace!");
		}();
		_uncompressedCigarString.push_back(cigarCharacter);
	
	}
	_startPosition = j;
	
	printDPTable(DPTable);
}

void DPAligner::dgsSW() {
	struct DPElem {
		int score;
		bool isInsertionOpened;
		bool isDeletionOpened;
	};
	
	DPElem *DPTable = (DPElem *)calloc(_n * m, sizeof(DPElem));
	
	auto get = [&DPTable, m=m](int i, int j) -> DPElem& {
		return DPTable[i * m + j];
	};
	
	pair<int,int> maxScoreIndex = {0, 0};
	for (int i = 1; i < _n; i++)
		for (int j = 1; j < m; j++) {
			DPElem& cur = get(i, j), snp = get(i - 1, j - 1), deletion = get(i, j - 1), insertion = get(i - 1, j);
			
			if (_reference[j - 1] == _query[i - 1])
				cur = { snp.score + MATCH_PENALTY, false, false};
			else {
				int deletionScore = deletion.score + (deletion.isDeletionOpened ? GAP_PENALTY : GAP_OPENING_PENALTY);
				int insertionScore = insertion.score + (insertion.isInsertionOpened ? GAP_PENALTY : GAP_OPENING_PENALTY);
				int snpScore = snp.score + SNP_PENALTY;
				
				if (snpScore >= deletionScore && snpScore >= insertionScore)
					cur = {snpScore, false, false}; // SNP
				else if (deletionScore >= insertionScore)
					cur = {deletionScore, false, true}; // DELETION
				else
					cur = {insertionScore, true, false}; // INSERTION
			}
			
			if (cur.score > _maxScore)
				std::tie(_maxScore, maxScoreIndex) = std::pair{cur.score, std::pair{i, j}};
		}
	
	// Backtrack result
	int i,j;
	std::tie(i, j) = maxScoreIndex;
	while (get(i, j).score > 0) {
		DPElem& cur = get(i, j), snp = get(i - 1, j - 1), deletion = get(i, j - 1), insertion = get(i - 1, j);
		
		char cigarCharacter;
		std::tie(cigarCharacter, i, j) = [&]() -> std::tuple<char, int, int> {
			if (cur.score == snp.score + MATCH_PENALTY && _reference[j - 1] == _query[i - 1])
				return {'M', i - 1, j - 1};
			else if (cur.score == snp.score + SNP_PENALTY)
				return {'S', i - 1, j - 1};
			else if (cur.score == deletion.score + (deletion.isDeletionOpened ? GAP_PENALTY : GAP_OPENING_PENALTY))
				return {'D', i, j - 1};
			else if (cur.score == insertion.score + (insertion.isInsertionOpened ? GAP_PENALTY : GAP_OPENING_PENALTY))
				return {'I', i - 1, j};
			else
				throw std::runtime_error("Cannot match according DP score during backtrace!");
		}();
		_uncompressedCigarString.push_back(cigarCharacter);
	}
	_startPosition = j;
}

int main(int argc, char *argv[]) {	
	// TODO: How do i realise 5'-/3'end clipping penalty and unpaired read pair penalty
	
	// const std::string reference = "panamabananaboatsanas";
	// const std::string query = "panamabananaboatsanans";
		
	// const std::string reference = parseFasta("../sample_data/Wuhan-Hu-1.fa");
	const std::string reference = "TAATGTATGT";
	const std::string query = "AAGTGCAA";
	
	DPAligner aligner(reference, query);
	
	// aligner.dgsSW();
	aligner.smithWaterman();
	aligner.compressCigarString();
	aligner.print();
	
}