#include <iostream>
#include <fstream>
#include <vector>
#include <unordered_map>
#include <set>
#include <algorithm>
#include <tuple>
#include <iomanip>
#include <set>
#include <cmath>

class BurrowsWheeler {
public:
	BurrowsWheeler(std::string reference) : _reference(reference + '$'), _n(_reference.size()), _suffixArray(_n), _occ(_n + 1) {
		createSuffixArray();
		createBWT();
		createFMIndex();
	}
	
	std::string _reference;
	int _n;
	std::vector<int> _suffixArray;
	std::string _bwt;
	
	std::unordered_map<char, int> _c;
	std::vector<std::unordered_map<char, int>> _occ;
	
	
	std::pair<int, int> query(std::string query) {
		std::reverse(query.begin(), query.end());
		
		int start = 0, end = _n;
		
		for (auto el : query) {
			start = _c[el] + _occ[start][el];
			end = _c[el] + _occ[end][el];
		}
		
		return {start, end};
	}
private:
	// O(ref * log^2(ref))
	void createSuffixArray();
	
	// O(ref)
	void createBWT();

	void createFMIndex();
};

void BurrowsWheeler::createSuffixArray() {
	struct substr { 					// substring of length 2^k
		std::pair<int, int> parts;		// two halfs of length 2^k−1
		int ind;						// starting index of substring
	};
	
	std::vector<std::vector<int>> c(ceil(log2(_n))+1, std::vector<int>(_n,0));		
	
	for (int i = 0; i < _n; i++)
		c[0][i] = _reference[i] - '$';
	std::vector<substr> p(_n);
	
	for (int k = 1, gap = 1; gap < _n; k++, gap *= 2) { // gap = 2^k−1
		for (int i = 0; i < _n; i++)
			p[i] = {{c[k - 1][i], c[k - 1][(i + gap) % _n]}, i};
		std::sort(p.begin(), p.end(), [](auto &&a, auto &&b) {return a.parts < b.parts;});
		
		for (int i = 1; i < _n; i++) {
			if (p[i].parts == p[i - 1].parts)
				c[k][p[i].ind] = c[k][p[i - 1].ind];
			else
				c[k][p[i].ind] = i;
		}
	}
	
	for (int i = 0; i < _n; i++)
		_suffixArray[c[c.size() - 1][i]] = i;
}

void BurrowsWheeler::createBWT() {
	for (int i = 0; i < _n; i++) {
		int cyclicIndex = _suffixArray[i] - 1;
		if (cyclicIndex == -1)
			cyclicIndex = _n - 1;
		_bwt.push_back(_reference[cyclicIndex]);
	}
}

void BurrowsWheeler::createFMIndex() {
	std::string sortedReference = _reference;
	std::sort(sortedReference.begin(), sortedReference.end()); // this is probably already a byproduct of createSuffixArray
	
	std::set uniqueSymbols(_reference.begin(), _reference.end());
	
	char currentSymbol = sortedReference[0];
	int lastSmaller = 0;
	for (int i = 0; i < _n; i++)
		if (sortedReference[i] != currentSymbol) 
		_c[currentSymbol] = lastSmaller, lastSmaller = i, currentSymbol = sortedReference[i];
	_c[currentSymbol] = lastSmaller;
	
	for (auto& symbol : uniqueSymbols)
		_occ[0][symbol] = 0;
	
	for (int i = 1; i <= _n; i++)
		for (auto& symbol : uniqueSymbols)
		_occ[i][symbol] = _occ[i - 1][symbol] + ((_bwt[i - 1] == symbol) ? 1 : 0);
	
}

int main(int argc, char *argv[]) {
	BurrowsWheeler bw("GTATAATGTATGTC");
	
	std::cout << "Suffix Array: " << std::endl;
	for (auto el : bw._suffixArray)
		std::cout << std::setw(2) << std::setfill('0') << el << ' ';

	std::cout << std::endl;
	
	std::cout << "BWT: " << std::endl;
	std::cout << bw._bwt << std::endl;
	
	std::cout << "c function: " << std::endl;
	for (auto& [key, value] : bw._c)
		std::cout << "{" << key << ", " << std::setw(2) << std::setfill('0') << value << "}, ";
	std::cout << std::endl;
	
	std::cout << "occ function: " << std::endl;
	for (int i = 0; i <= bw._n; i++) {
		for (auto& [key, value] : bw._occ[i])
			std::cout << "{" << key << ", " << std::setw(2) << std::setfill('0') << value << "}, ";
		std::cout << std::endl;
	}
	std::cout << std::endl;
	
	std::string query("CTG");
	auto [start, end] = bw.query(query);
	std::cout << "SA Interval of \"" << query << "\": [" << start << ", " << end << "[" << std::endl;
}