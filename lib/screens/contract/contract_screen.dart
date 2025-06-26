import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contract_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';

class ContractScreen extends StatefulWidget {
  final ContractModel contract;

  const ContractScreen({
    Key? key,
    required this.contract,
  }) : super(key: key);

  @override
  _ContractScreenState createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser = userProvider.user;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isClient = currentUser.uid == widget.contract.clientId;
        final isProfessional = currentUser.uid == widget.contract.professionalId;

        return Scaffold(
          appBar: AppBar(
            title: Text('契約: ${widget.contract.title}'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '概要'),
                Tab(text: 'メッセージ'),
                Tab(text: 'マイルストーン'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(currentUser, isClient, isProfessional),
              _buildMessagesTab(currentUser),
              _buildMilestonesTab(currentUser, isClient, isProfessional),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(UserModel currentUser, bool isClient, bool isProfessional) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 契約状況カード
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        color: widget.contract.status.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '契約状況',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.contract.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.contract.status.displayName,
                          style: TextStyle(
                            color: widget.contract.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('契約金額', '¥${widget.contract.price.toStringAsFixed(0)}'),
                  _buildInfoRow('予定期間', '${widget.contract.estimatedDays}日'),
                  _buildInfoRow('開始日', _formatDate(widget.contract.startDate)),
                  _buildInfoRow('予定完了日', _formatDate(widget.contract.expectedEndDate)),
                  if (widget.contract.actualEndDate != null)
                    _buildInfoRow('実際の完了日', _formatDate(widget.contract.actualEndDate!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 参加者情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '参加者',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<UserModel?>(
                    future: Provider.of<DatabaseService>(context, listen: false)
                        .getUser(widget.contract.clientId),
                    builder: (context, clientSnapshot) {
                      return FutureBuilder<UserModel?>(
                        future: Provider.of<DatabaseService>(context, listen: false)
                            .getUser(widget.contract.professionalId),
                        builder: (context, professionalSnapshot) {
                          return Column(
                            children: [
                              _buildParticipantRow(
                                '依頼者',
                                clientSnapshot.data,
                                Icons.person,
                              ),
                              const SizedBox(height: 12),
                              _buildParticipantRow(
                                '専門家',
                                professionalSnapshot.data,
                                Icons.work,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // アクションボタン
          if (widget.contract.status == ContractStatus.active) ...[
            if (isProfessional) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeContract(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('作業完了報告'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelContract(),
                icon: const Icon(Icons.cancel),
                label: const Text('契約をキャンセル'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesTab(UserModel currentUser) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ContractMessage>>(
            stream: Provider.of<DatabaseService>(context, listen: false)
                .getContractMessages(widget.contract.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('まだメッセージがありません'),
                );
              }

              final messages = snapshot.data!;
              return ListView.builder(
                controller: _messagesScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMyMessage = message.senderId == currentUser.uid;
                  return _buildMessageBubble(message, isMyMessage);
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMilestonesTab(UserModel currentUser, bool isClient, bool isProfessional) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.contract.milestones.length,
      itemBuilder: (context, index) {
        final milestone = widget.contract.milestones[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Icon(
              milestone.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: milestone.isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(milestone.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.description),
                const SizedBox(height: 4),
                Text(
                  '期限: ${_formatDate(milestone.dueDate)}',
                  style: TextStyle(
                    color: milestone.dueDate.isBefore(DateTime.now()) && !milestone.isCompleted
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                ),
                if (milestone.completedAt != null)
                  Text(
                    '完了: ${_formatDate(milestone.completedAt!)}',
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
            trailing: isProfessional && !milestone.isCompleted
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _completeMilestone(milestone),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(String role, UserModel? user, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          role,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        if (user != null) ...[
          ProfileAvatar(
            imageUrl: user.profileImageUrl,
            radius: 16,
          ),
          const SizedBox(width: 8),
          Text(user.displayName),
        ] else
          const Text('読み込み中...'),
      ],
    );
  }

  Widget _buildMessageBubble(ContractMessage message, bool isMyMessage) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMyMessage) ...[
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.message,
              style: TextStyle(
                color: isMyMessage ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMyMessage ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'メッセージを入力...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    final message = ContractMessage(
      id: '',
      contractId: widget.contract.id,
      senderId: currentUser.uid,
      senderName: currentUser.displayName,
      senderProfileImageUrl: currentUser.profileImageUrl,
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
      type: ContractMessageType.text,
    );

    try {
      await context.read<DatabaseService>().sendContractMessage(message);
      _messageController.clear();
      
      // メッセージリストの最下部にスクロール
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messagesScrollController.hasClients) {
          _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージの送信に失敗しました: $e')),
      );
    }
  }

  void _completeContract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('作業完了報告'),
        content: const Text('作業が完了しましたか？\n完了報告後、依頼者による確認が行われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('完了報告'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<DatabaseService>().completeContract(widget.contract.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作業完了を報告しました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完了報告に失敗しました: $e')),
        );
      }
    }
  }

  void _cancelContract() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('契約キャンセル'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('契約をキャンセルする理由を入力してください。'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'キャンセル理由',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('戻る'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await context.read<DatabaseService>().cancelContract(widget.contract.id, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('契約をキャンセルしました')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('キャンセルに失敗しました: $e')),
        );
      }
    }
  }

  void _completeMilestone(ContractMilestone milestone) async {
    try {
      await context.read<DatabaseService>().completeMilestone(
        widget.contract.id,
        milestone.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${milestone.title}を完了しました')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('マイルストーン完了に失敗しました: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 