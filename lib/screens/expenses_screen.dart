import 'package:flutter/material.dart';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Expense> _filtered = [];
  String _selectedCat = 'الكل';
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getAllExpenses();
    setState(() {
      _expenses = all;
      _applyFilter();
    });
  }

  void _applyFilter() {
    _filtered = _expenses.where((e) {
      final catMatch = _selectedCat == 'الكل' || e.category == _selectedCat;
      final searchMatch = _search.isEmpty ||
          e.description.toLowerCase().contains(_search.toLowerCase()) ||
          e.category.toLowerCase().contains(_search.toLowerCase());
      return catMatch && searchMatch;
    }).toList();
  }

  Future<void> _delete(Expense e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف "${e.description}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteExpense(e.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final categories = ['الكل', ...ExpenseCategory.all.map((c) => c.nameAr)];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isAr ? 'قائمة النفقات' : 'Liste des dépenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text('${_filtered.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // بحث
          Container(
            color: const Color(0xFF1A3A5C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: isAr ? 'بحث...' : 'Rechercher...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () => setState(() { _search = ''; _searchCtrl.clear(); _applyFilter(); }))
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // فلتر الفئات
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat == _selectedCat;
                return GestureDetector(
                  onTap: () => setState(() { _selectedCat = cat; _applyFilter(); }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF1A3A5C) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFF1A3A5C) : Colors.grey.shade300),
                    ),
                    child: Text(cat == 'الكل' ? (isAr ? 'الكل' : 'Tout') : cat,
                      style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),

          // المجموع المصفى
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAr ? 'المجموع:' : 'Total:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  '${_filtered.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C), fontSize: 15),
                ),
              ],
            ),
          ),

          // القائمة
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _filtered.isEmpty
                  ? Center(child: Text(isAr ? 'لا توجد نفقات' : 'Aucune dépense', style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _ExpenseTile(
                        expense: _filtered[i],
                        isAr: isAr,
                        onDelete: () => _delete(_filtered[i]),
                        onEdit: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddExpenseScreen(expense: _filtered[i]),
                          ));
                          _load();
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final bool isAr;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ExpenseTile({required this.expense, required this.isAr, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cat = ExpenseCategory.findByName(expense.category);
    final color = cat != null ? Color(cat.colorValue) : const Color(0xFF888888);
    final icon = cat?.icon ?? '📦';

    return Dismissible(
      key: Key('${expense.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onLongPress: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(expense.category, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        Text(expense.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${expense.amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(isAr ? 'درهم' : 'DH', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
