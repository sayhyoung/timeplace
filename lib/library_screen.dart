import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'services/capture_db.dart';
import 'services/capture_record.dart';
import 'services/share_service.dart';
import 'topper_template.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  TopperCategory? _category;
  TimeOfDayBucket? _timeBucket;
  CaptureSortBy _sort = CaptureSortBy.capturedDesc;
  int? _folderId;
  String _query = '';
  final Set<int> _locallyRemovedIds = {};
  late Future<_LibraryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LibraryData> _load() async {
    final folders = await CaptureDb.folders();
    final records = await CaptureDb.query(
      memoQuery: _query.isEmpty ? null : _query,
      sort: _sort,
    );
    return _LibraryData(records: records, folders: folders);
  }

  void _refresh() => setState(() => _future = _load());

  List<CaptureRecord> _filteredRecords(List<CaptureRecord> records) {
    return records.where((record) {
      final folderMatches = _folderId == null || record.folderId == _folderId;
      final categoryMatches = _category == null || record.category == _category;
      final timeMatches =
          _timeBucket == null || record.timeBucket == _timeBucket;
      final wasRemoved =
          record.id != null && _locallyRemovedIds.contains(record.id);
      return !wasRemoved && folderMatches && categoryMatches && timeMatches;
    }).toList();
  }

  void _removeRecord(CaptureRecord record) {
    final id = record.id;
    if (id != null) {
      setState(() => _locallyRemovedIds.add(id));
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 라이브러리'),
        actions: [
          IconButton(
            tooltip: '폴더 만들기',
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createFolder,
          ),
          PopupMenuButton<CaptureSortBy>(
            icon: const Icon(Icons.sort),
            tooltip: '정렬',
            initialValue: _sort,
            onSelected: (v) {
              _sort = v;
              _refresh();
            },
            itemBuilder: (_) => CaptureSortBy.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.title)))
                .toList(),
          ),
        ],
      ),
      body: FutureBuilder<_LibraryData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return Column(
            children: [
              _buildSearch(),
              if (data != null) _buildFolderChips(data.folders),
              _buildCategoryChips(),
              _buildTimeChips(),
              const Divider(height: 1),
              Expanded(
                child: data == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildGrid(_filteredRecords(data.records), data.folders),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<CaptureRecord> records, List<CaptureFolder> folders) {
    if (records.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '조건에 맞는 사진이 없습니다.\n필터를 바꾸거나 새로 촬영해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: records.length,
      itemBuilder: (_, i) => _CaptureTile(
        record: records[i],
        folders: folders,
        onChanged: _refresh,
        onDeleted: _removeRecord,
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: '메모 검색',
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (v) {
          _query = v;
          _refresh();
        },
      ),
    );
  }

  Widget _buildFolderChips(List<CaptureFolder> folders) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _chip('전체 폴더', _folderId == null, () {
            _folderId = null;
            setState(() {});
          }),
          ...folders.map(
            (f) => _chip('📁 ${f.name}', _folderId == f.id, () {
              _folderId = _folderId == f.id ? null : f.id;
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _chip('전체', _category == null, () {
            _category = null;
            setState(() {});
          }),
          ...TopperCategory.values.map(
            (c) => _chip('${c.emoji} ${c.title}', _category == c, () {
              _category = _category == c ? null : c;
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _chip('전체 시간대', _timeBucket == null, () {
            _timeBucket = null;
            setState(() {});
          }),
          ...TimeOfDayBucket.values.map(
            (b) => _chip('${b.emoji} ${b.title}', _timeBucket == b, () {
              _timeBucket = _timeBucket == b ? null : b;
              setState(() {});
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('폴더 만들기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 5월 식단 기록'),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await CaptureDb.createFolder(trimmed);
    _refresh();
  }
}

class _CaptureTile extends StatelessWidget {
  final CaptureRecord record;
  final List<CaptureFolder> folders;
  final VoidCallback onChanged;
  final ValueChanged<CaptureRecord> onDeleted;

  const _CaptureTile({
    required this.record,
    required this.folders,
    required this.onChanged,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(record.thumbnailPath);
    return GestureDetector(
      onTap: () => _showDetail(context),
      onLongPress: () => _confirmDelete(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (file.existsSync())
            Image.file(file, fit: BoxFit.cover)
          else
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('M/d HH:mm').format(record.capturedAt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (record.category != null)
            Positioned(
              right: 4,
              top: 4,
              child: Text(
                record.category!.emoji,
                style: const TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(_displayFile(record), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('yyyy.MM.dd HH:mm').format(record.capturedAt),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (record.address != null) ...[
                const SizedBox(height: 4),
                Text(
                  record.address!,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              if (record.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('💬 ${record.memo}'),
              ],
              const SizedBox(height: 8),
              Text(
                '저장: ${DateFormat('yyyy.MM.dd HH:mm').format(record.savedAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: record.stampedPath == null
                          ? null
                          : () => _share(context),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('공유'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveToAlbum(context),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('앨범 저장'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: record.id == null
                          ? null
                          : () => _chooseFolder(context),
                      icon: const Icon(Icons.folder_outlined),
                      label: const Text('폴더'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: () async {
                      final sheetNavigator = Navigator.of(sheetContext);
                      final deleted = await _confirmDelete(sheetContext);
                      if (deleted && sheetNavigator.canPop()) {
                        sheetNavigator.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.stampedPath == null
                    ? '이전 기록이라 앱에는 썸네일만 남아 있습니다.'
                    : '앱 라이브러리에 원본과 스탬프 적용본을 함께 보관 중입니다.',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 시트 반환 sentinel: -1=폴더에서 빼기, -2=새 폴더 만들기
  Future<void> _chooseFolder(BuildContext context) async {
    final id = await showModalBottomSheet<int?>(
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '폴더로 이동',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('새 폴더 만들기'),
                onTap: () => Navigator.pop(context, -2),
              ),
              if (record.folderId != null)
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: const Text('폴더에서 빼기'),
                  onTap: () => Navigator.pop(context, -1),
                ),
              if (folders.isEmpty && record.folderId == null)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '아직 만든 폴더가 없습니다. 새 폴더를 만들어 보세요.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
              for (final f in folders)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(f.name),
                  selected: record.folderId == f.id,
                  trailing: record.folderId == f.id
                      ? const Icon(Icons.check, color: Color(0xFF1F7A5C))
                      : null,
                  onTap: () => Navigator.pop(context, f.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (id == null || record.id == null) return;

    int? targetFolderId;
    if (id == -1) {
      targetFolderId = null;
    } else if (id == -2) {
      if (!context.mounted) return;
      final name = await _promptFolderName(context);
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      targetFolderId = await CaptureDb.createFolder(trimmed);
    } else {
      targetFolderId = id;
    }

    await CaptureDb.updateFolder(record.id!, targetFolderId);
    if (context.mounted) Navigator.pop(context);
    onChanged();
  }

  Future<String?> _promptFolderName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('폴더 만들기'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 5월 식단 기록'),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('라이브러리에서 삭제'),
        content: const Text('이 항목을 라이브러리에서 삭제할까요?\n갤러리에 저장된 사진은 그대로 남습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || record.id == null) return false;
    for (final path in [
      record.thumbnailPath,
      record.originalPath,
      record.stampedPath,
    ]) {
      if (path == null) continue;
      try {
        await File(path).delete();
      } catch (_) {}
    }
    await CaptureDb.delete(record.id!);
    onDeleted(record);
    return true;
  }

  File _displayFile(CaptureRecord record) {
    final stampedPath = record.stampedPath;
    if (stampedPath != null && File(stampedPath).existsSync()) {
      return File(stampedPath);
    }
    return File(record.thumbnailPath);
  }

  /// 라이브러리 사진(스탬프 적용본 우선)을 기기 갤러리/앨범에 저장한다.
  /// 다이어리 등 다른 앱에서 사진을 불러 쓸 수 있게 한다.
  Future<void> _saveToAlbum(BuildContext context) async {
    final file = _displayFile(record);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!file.existsSync()) {
        messenger.showSnackBar(
          const SnackBar(content: Text('원본 파일을 찾을 수 없습니다.')),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      await Gal.putImageBytes(
        bytes,
        name: 'timeplace_${DateTime.now().millisecondsSinceEpoch}',
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('앨범에 저장했습니다.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('앨범 저장에 실패했습니다. 저장 권한을 확인해 주세요.')),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    final path = record.stampedPath;
    if (path == null) return;
    try {
      final sharePath = await CaptureFiles.saveForShare(
        await File(path).readAsBytes(),
      );
      await ShareService.shareImage(sharePath, text: '인증샷 카메라');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유를 시작하지 못했습니다.')));
    }
  }
}

class _LibraryData {
  final List<CaptureRecord> records;
  final List<CaptureFolder> folders;

  const _LibraryData({required this.records, required this.folders});
}
