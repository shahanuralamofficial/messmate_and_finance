import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/finance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/translations.dart';
import '../widgets/bottom_nav_bar.dart';
import 'add_edit_note_screen.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  void _navigateToAddEdit(BuildContext context, {Note? note}) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditNoteScreen(note: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = Provider.of<FinanceProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locale = settings.locale.languageCode;
    final isBangla = locale == 'bn';
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(AppTranslations.translate('notes', locale), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [Colors.black, const Color(0xFF334155)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (financeProvider.pinnedNotes.isNotEmpty) ...[
                    _buildSectionHeader(isBangla ? 'পিন করা নোট' : 'Pinned Notes', isDark),
                    const SizedBox(height: 12),
                    ...financeProvider.pinnedNotes.map((note) => _buildProfessionalNoteCard(context, note, authProvider.user!.uid, financeProvider, isDark)),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionHeader(isBangla ? 'সব নোট' : 'All Notes', isDark),
                  const SizedBox(height: 12),
                  if (financeProvider.unpinnedNotes.isEmpty && financeProvider.pinnedNotes.isEmpty)
                    _buildEmptyState(isBangla ? 'কোন নোট নেই' : 'No notes found', isDark)
                  else
                    ...financeProvider.unpinnedNotes.map((note) => _buildProfessionalNoteCard(context, note, authProvider.user!.uid, financeProvider, isDark)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(context),
        label: Text(isBangla ? 'নতুন নোট' : 'New Note'),
        icon: const Icon(Icons.edit_note_rounded),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(color: isDark ? Colors.blueAccent : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }

  Widget _buildProfessionalNoteCard(BuildContext context, Note note, String userId, FinanceProvider fp, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToAddEdit(context, note: note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: note.isPinned ? Colors.blueAccent : Colors.grey[400]),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        fp.togglePinNote(userId, note.id);
                      },
                    ),
                  ],
                ),
                Text(
                  note.content,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM, yyyy').format(note.updatedAt),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.vibrate(); // Fixed: changed warningImpact to vibrate
                        fp.deleteNote(userId, note.id);
                      },
                      child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.7), size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.notes_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
