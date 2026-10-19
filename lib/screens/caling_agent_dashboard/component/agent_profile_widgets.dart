import 'package:flutter/material.dart';
import 'package:talk24loves/components/app_colors.dart';

// 🔍 बॉटम शीट सर्च पिकर (स्टेट, सिटी और लैंग्वेज के लिए नीचे से खुलने वाला कार्ड)
void showSearchableBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required Function(String) onSelected,
  required bool isDarkMode,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      TextEditingController searchController = TextEditingController();
      List<String> filteredItems = List.from(items);

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search $title...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryPink,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.black26
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        filteredItems = items
                            .where(
                              (item) => item.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            filteredItems[index],
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                            ),
                          ),
                          onTap: () {
                            onSelected(filteredItems[index]);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  const HeaderButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withOpacity(0.7)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final Color background;
  final Color borderColor;

  const ProfileAvatar({
    required this.avatarUrl,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: borderColor.withOpacity(0.8), width: 1.2),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const AvatarFallback(),
              )
            : const AvatarFallback(),
      ),
    );
  }
}

class AvatarFallback extends StatelessWidget {
  const AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryPink.withOpacity(0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.primaryPink,
        size: 36,
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color primaryText;
  final Color secondaryText;
  final Color background;
  final Color borderColor;

  const InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.primaryText,
    required this.secondaryText,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
