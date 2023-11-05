#include <iostream>
#include <cstring>
#include <string>
#include <stack>
#include <vector>
#include <map>
#include <iomanip>
#include <algorithm>
using namespace std;

int stateall = 0;
int dfaall = 0;
int finalall = 0;
char transmatrix[1000][1000];
char transmatrix2[1000][1000];
char transmatrix3[1000][1000];
vector<char> album_set;
char ss[400];
char s[200];
class state;
state *allst;

class state {
	public:
		int statenum;
		bool is_end, is_start;
		map<char, state *> transition;
		vector<state *> eps_trans;
		state(bool a, bool b) {
			is_start = a;
			is_end = b;
			if (stateall == 0)
				allst = this;
			statenum = stateall++;
		}
		void add_transition(state *to, char c) {
			transition[c] = to;
			transmatrix[statenum][to->statenum] = c;
		}
		void add_eps_transition(state *to) {
			eps_trans.push_back(to);
			transmatrix[statenum][to->statenum] = '-';
		}

};

class NFA {
	public:
		state *stnode, *endnode;
		NFA(state *a, state *b) {
			stnode = a;
			endnode = b;
		}
};

class DFA {
	public:
		int statenum;
		bool is_end, is_start;
		vector<state *> nfa_set;
		map<char, int> nxt;
		DFA(vector<state *> newset, bool a, bool b) {
			for (int i = 0; i < newset.size(); i++) {
				nfa_set.push_back(newset[i]);
			}
			is_start = a;
			is_end = b;
			statenum = dfaall++;
		}
};

class finalNode {
	public:
		int statenum;
		bool is_start, is_end;
		vector<DFA *> dfa_set;
		map<char, finalNode *> transition;
		finalNode(vector<DFA *> newset, bool a, bool b) {
			for (int i = 0; i < newset.size(); i++) {
				dfa_set.push_back(newset[i]);
			}
			is_start = a;
			is_end = b;
			statenum = finalall++;
		}
};


char postfix[100];
stack<NFA *> nfastack;
vector<DFA *> dfa_state_list;
vector<finalNode *> list_final;//最后用到的闭包
vector<finalNode *> closure_list;//中间用到的闭包
map<char, finalNode *> finalmap[100];

int getprec(char a) {
	if (a == '*')
		return 100;
	if (a == '+')
		return 100;
	if (a == '?')
		return 100;
	if (a == '.')
		return 80;
	if (a == '|')
		return 60;
	if (a == '|')
		return 20;
	return 0;
}

void getpostfix(char *s) {
	int len = strlen(s);
	int postnum = 0; //当前postifx输出到哪里了
	stack<char> opstack;
	for (int i = 0; i < len; i++) {
		if (s[i] == '(') {
			//遇到左括号，入栈
			opstack.push(s[i]);
		} else if (s[i] == ')') {
			//遇到右括号，出栈直到遇到左括号
			while (opstack.top() != '(' && opstack.empty() == false) {
				char tmp = opstack.top();
				postfix[postnum++] = tmp;
				opstack.pop();
			}
			if (opstack.top() == '(')
				opstack.pop();
		} else if (s[i] == '*' || s[i] == '+' || s[i] == '?' || s[i] == '.' || s[i] == '|') {
			//遇到操作符，如果栈顶元素优先级大于等于当前操作符，出栈
			while (opstack.empty() == false && getprec(s[i]) <= getprec(opstack.top())) {
				char tmp = opstack.top();
				postfix[postnum++] = tmp;
				opstack.pop();
			}
			opstack.push(s[i]);
		} else {
			//遇到操作数，直接输出
			postfix[postnum++] = s[i];
		}
	}
	while (opstack.empty() == false) {
		char tmp = opstack.top();
		postfix[postnum++] = tmp;
		opstack.pop();
	}
}

void createNFA() {
	int len = strlen(postfix);
	for (int i = 0; i < len; i++) {
		if (postfix[i] == '.') {
			NFA *nfa2 = nfastack.top();
			nfastack.pop();
			NFA *nfa1 = nfastack.top();
			nfastack.pop();
			nfa1->endnode->is_end = false;
			nfa2->stnode->is_start = false;
			nfa1->stnode->is_start = true;
			nfa1->endnode->add_eps_transition(nfa2->stnode);
			nfastack.push(new NFA(nfa1->stnode, nfa2->endnode));
		} else if (postfix[i] == '|') {
			NFA *nfa2 = nfastack.top();
			nfastack.pop();
			NFA *nfa1 = nfastack.top();
			nfastack.pop();
			state *start = new state(true, false);
			state *end = new state(false, true);
			start->add_eps_transition(nfa1->stnode);
			start->add_eps_transition(nfa2->stnode);
			nfa1->endnode->add_eps_transition(end);
			nfa2->endnode->add_eps_transition(end);
			nfa1->endnode->is_end = false;
			nfa2->endnode->is_end = false;
			nfa1->stnode->is_end = false;
			nfa2->stnode->is_end = false;
			nfastack.push(new NFA(start, end));
		} else if (postfix[i] == '*') {
			NFA *nfa = nfastack.top();
			nfastack.pop();
			state *start = new state(true, false);
			state *end = new state(false, true);
			start->add_eps_transition(nfa->stnode);
			nfa->endnode->add_eps_transition(end);
			nfa->endnode->add_eps_transition(nfa->stnode);
			start->add_eps_transition(end);
			nfa->endnode->is_end = false;
			nfa->stnode->is_start = false;
			nfastack.push(new NFA(start, end));
		} else if (postfix[i] == '+') {
			NFA *nfa = nfastack.top();
			nfastack.pop();
			state *start = new state(true, false);
			state *end = new state(false, true);
			start->add_eps_transition(nfa->stnode);
			nfa->endnode->add_eps_transition(end);
			nfa->endnode->add_eps_transition(nfa->stnode);
			nfa->endnode->is_end = false;
			nfa->stnode->is_start = false;
			nfastack.push(new NFA(start, end));
		} else if (postfix[i] == '?') {
			NFA *nfa = nfastack.top();
			nfastack.pop();
			state *start = new state(true, false);
			state *end = new state(false, true);
			start->add_eps_transition(nfa->stnode);
			nfa->endnode->add_eps_transition(end);
			start->add_eps_transition(end);
			nfa->endnode->is_end = false;
			nfa->stnode->is_start = false;
			nfastack.push(new NFA(start, end));
		} else {
			//构造一个NFA
			state *start = new state(true, false);
			state *end = new state(false, true);
			start->add_transition(end, postfix[i]);
			nfastack.push(new NFA(start, end));
			if (find(album_set.begin(), album_set.end(), postfix[i]) == album_set.end())
				album_set.push_back(postfix[i]);
		}
	}
}

void find_epsilon(vector<state *> *cur_closure) {
	stack<state *> state_stack;
	// 将闭包中的结点全部入栈
	for (int i = 0; i < cur_closure->size(); i++) {
		state_stack.push((*cur_closure)[i]);
	}
	while (!state_stack.empty()) {//栈不为空
		state *tmp = state_stack.top();
		state_stack.pop();
		for (int i = 0; i < tmp->eps_trans.size(); i++) {
			if (find(cur_closure->begin(), cur_closure->end(), tmp->eps_trans[i]) == cur_closure->end()) {
				state_stack.push(tmp->eps_trans[i]);
				cur_closure->push_back(tmp->eps_trans[i]);
			}
		}
	}
}

bool test_end(vector<state *> *cur_closure) {
	for (int i = 0; i < cur_closure->size(); i++) {
		if (((*cur_closure)[i])->is_end)
			return true;
	}
	return false;
}

int have_dfa(vector<state *> *cur_closure) {
	for (int i = 0; i < dfa_state_list.size(); i++) {
		bool flag = 0;
		vector<state *> *tmp = &(dfa_state_list[i]->nfa_set);
		for (int j = 0; j < cur_closure->size(); j++) {
			if (find(tmp->begin(), tmp->end(), (*cur_closure)[j]) == tmp->end()) {
				flag = 1;
				break;
				//不包含于该集合
			}
		}
		if (flag == 0) {
			// 包含于该集合
			return i;
		}
	}
	return -1;
}

void nfa2dfa() {
	state *start = allst;
	vector<state *> start_closure;
	vector<DFA *> closure_list;
	start_closure.push_back(allst);
	bool have_end = false;
	// 找e闭包
	find_epsilon(&start_closure);
	//cout << start->statenum << endl;
	//cout << start_closure.size() << endl;
	have_end = test_end(&start_closure);
	cout << have_end << endl;

	DFA *new_closure = new DFA(start_closure, true, have_end);
	closure_list.push_back(new_closure);//存得到的闭包
	dfa_state_list.push_back(new_closure);//存得到的dfa状态列表

	while (closure_list.size()) {
		DFA *tmp = closure_list.back();
		closure_list.pop_back();
		//取当前闭包的一个
		//move_closure 存当前得到的闭包
		for (int i = 0; i < album_set.size(); i++) {
			//遍历所有字符
			vector<state *> move_closure;
			for (int j = 0; j < tmp->nfa_set.size(); j++) {
				if (((tmp->nfa_set)[j]->transition).find(album_set[i]) == ((tmp->nfa_set)[j]->transition).end())
					continue;
				// 遍历闭包中的每一个状态
				if (find(move_closure.begin(), move_closure.end(),
				         ((tmp->nfa_set)[j]->transition)[album_set[i]]) == move_closure.end()) {
					move_closure.push_back(((tmp->nfa_set)[j]->transition)[album_set[i]]);
				}
			}
			//cout << move_closure.size();
			find_epsilon(&move_closure);
			int dfa_find_id = have_dfa(&move_closure);
			if (move_closure.size() != 0 && dfa_find_id == -1) {
				have_end = test_end(&move_closure);
				DFA *new_closure = new DFA(move_closure, false, have_end);
				dfa_state_list.push_back(new_closure);
				closure_list.push_back(new_closure);
				tmp->nxt[album_set[i]] = new_closure->statenum;
				transmatrix2[tmp->statenum][new_closure->statenum] = album_set[i];
			} else if (move_closure.size() != 0 && dfa_find_id != -1) {
				tmp->nxt[album_set[i]] = dfa_find_id;
				transmatrix2[tmp->statenum][dfa_find_id] = album_set[i];
			}
		}
	}
}

bool differ(vector<finalNode *> *a, vector<finalNode *> *b) {
	for (int i = 0; i < a->size(); i++) {
		if (find(b->begin(), b->end(), (*a)[i]) != b->end())
			return false;
	}
	return true;
}

void give(vector<finalNode *> *a, vector<finalNode *> *b) {
	b->clear();
	for (int i = 0; i < a->size(); i++) {
		b->push_back((*a)[i]);
	}
}

void minidfa() {
	//vector<finalNode *> minidfa_closure;//最终的闭包结果
	vector<DFA *> A;
	vector<DFA *> B;//end
	for (int i = 0; i < dfa_state_list.size(); i++) {
		if (dfa_state_list[i]->is_end)
			B.push_back(dfa_state_list[i]);
		else {
			A.push_back(dfa_state_list[i]);
		}
	}
	//cout << A.size();
	//cout << B.size();
	list_final.push_back(new finalNode(A, true, false));
	list_final.push_back(new finalNode(B, false, true));
	for (int i = 0; i < album_set.size(); i++) {
		// 选择一条边
		while (differ(&closure_list, &list_final)) {
			give(&list_final, &closure_list);
			list_final.clear();
			for (int z = 0; z < closure_list.size(); z++) {
				finalNode *tmp = closure_list[z];
				//if (tmp->dfa_set.size() == 1) {
				//	list_final.push_back(tmp);
				//	continue;
				//}
				// 对于每一条边
				//对于其中的每一个节点，进行move
				vector<pair<DFA *, int>> cur_closure;
				vector<DFA *> nouse_closure;
				bool has_start2 = false;
				bool has_end2 = false;
				for (int j = 0; j < tmp->dfa_set.size(); j++) {
					if (((tmp->dfa_set)[j]->nxt).find(album_set[i]) != ((tmp->dfa_set)[j]->nxt).end()) {
						cur_closure.push_back(make_pair((tmp->dfa_set)[j], (tmp->dfa_set)[j]->nxt[album_set[i]]));
						//空集合
					} else {
						nouse_closure.push_back((tmp->dfa_set)[j]);
						if ((tmp->dfa_set)[j]->is_start)
							has_start2 = 1;
						if ((tmp->dfa_set)[j]->is_end)
							has_end2 = 1;
					}
				}
				if (nouse_closure.size() != 0 && nouse_closure.size() != tmp->dfa_set.size()) {
					//一定需要分裂
					//cout << "sure";
					//closure_list.pop_back();
					// 0 - lenn-2
					list_final.push_back(new finalNode(nouse_closure, has_start2, has_end2));
					// 0 - lenn-1
				} else if (nouse_closure.size() == tmp->dfa_set.size()) {
					list_final.push_back(tmp);
				}
				//看lon是否属于一个闭包
				for (int j = 0; j < closure_list.size(); j++) {
					//cout << "j" << j;
					finalNode *cur = closure_list[j];
					int flag = 0;
					vector<DFA *> usenow;
					bool has_start = false;
					bool has_end = false;
					for (int m = 0; m < cur_closure.size(); m++) {
						bool mflag = false;
						for (int k = 0; k < cur->dfa_set.size(); k++) {
							if (cur_closure[m].second == (cur->dfa_set)[k]->statenum) {
								flag++;
								mflag = true;
								//忘写了！！！判断是否有这个元素再加进去
								usenow.push_back(cur_closure[m].first);
								if ((cur_closure[m].first)->is_start)
									has_start = true;
								if ((cur_closure[m].first)->is_end)
									has_end = true;
								break;
							}
						}
					}
					if (flag == tmp->dfa_set.size()) {
						//全部属于当前，不用分裂
						//cout << "===";
						//closure_list.pop_back();
						list_final.push_back(tmp);
						break;
					} else {
						//不属于当前，继续寻找
						if (flag == 0)
							continue;
						else {
							//需要分裂
							finalNode *createnode = new finalNode(usenow, has_start, has_end);
							list_final.push_back(createnode);
						}
					}
				}
			}
		}
		closure_list.clear();
	}

}

int main() {

	cin >> s;
	int lenss = 0;

	for (int i = 0; i < strlen(s); i++) {
		cout << s[i];
		if (i == 0) {
			ss[lenss++] = s[i];
			continue;
		}
		if (s[i] != '|' && s[i] != '*' && s[i] != '+' && s[i] != '?' && s[i] != ')') {
			if (s[i - 1] == '|' || s[i - 1] == '(') {
				ss[lenss++] = s[i];
				continue;
			}
			ss[lenss++] = '.';
			ss[lenss++] = s[i];
		} else {
			ss[lenss++] = s[i];
		}
	}
	getpostfix(ss);
	cout << postfix;
	createNFA();
	cout << endl;
	//cout << stateall << endl;
	//cout << allst->statenum << endl;
	//输出
	cout << setw(4) << " ";

	for (int i = 0; i < stateall; i++) {
		cout << setw(4) << i;
	}
	cout << endl;

	for (int i = 0; i < stateall; i++) {
		cout << setw(4) << i;
		for (int j = 0; j < stateall; j++) {
			cout << setw(4) << transmatrix[i][j];
		}
		cout << endl;
	}
	nfa2dfa();
	//cout << "dfa_size:" << dfa_state_list.size() << endl;
	//输出
	cout << endl;
	cout << setw(4) << " ";
	for (int i = 0; i < dfaall; i++) {
		cout << setw(4) << i;
	}
	cout << endl;

	for (int i = 0; i < dfaall; i++) {
		cout << setw(4) << i;
		for (int j = 0; j < dfaall; j++) {
			cout << setw(4) << transmatrix2[i][j];
		}
		cout << endl;
	}
	minidfa();
	//cout << "size" << list_final.size() << endl;
	//输出
	finalNode *stt;
	finalNode *endd;
	for (int i = 0; i < list_final.size(); i++) {
		if (list_final[i]->is_start == true)
			stt = list_final[i];
		if (list_final[i]->is_end == true)
			endd = list_final[i];
		for (int j = 0; j < list_final.size(); j++) {
			for (int k = 0; k < list_final[i]->dfa_set.size(); k++) {
				for (int l = 0; l < list_final[j]->dfa_set.size(); l++) {
					if (transmatrix2[list_final[i]->dfa_set[k]->statenum][list_final[j]->dfa_set[l]->statenum] != '\0'
					        && transmatrix2[list_final[i]->dfa_set[k]->statenum][list_final[j]->dfa_set[l]->statenum] != '-') {
						transmatrix3[list_final[i]->statenum]
						[list_final[j]->statenum] =
						    transmatrix2[list_final[i]->dfa_set[k]->statenum][list_final[j]->dfa_set[l]->statenum];
						finalmap[list_final[i]->statenum][transmatrix2[list_final[i]->dfa_set[k]->statenum][list_final[j]->dfa_set[l]->statenum]]
						    = list_final[j];
					}
				}
			}
		}
	}
	char getss;
	getchar();
	while (getss = getchar()) {
		getchar();
		if (finalmap[stt->statenum].find(getss) != finalmap[stt->statenum].end()) {
			stt = finalmap[stt->statenum][getss];
			if (stt->is_end)
				cout << "成功";
			continue;
		} else {
			cout << "失败";
			return 0;
		}
	}
}