// ==========================================
// UserHomeController.dart (Updated with Call Type Filter)
// ==========================================
import 'package:get/get.dart';
import 'package:talk24loves/screens/userSection/model/AgentModel.dart';

class UserHomeController extends GetxController {
  final RxList categories = [
    CategoryModel(id: '0', name: 'All'),
    CategoryModel(id: '1', name: 'Star'),
    CategoryModel(id: '2', name: 'Relationship'),
    CategoryModel(id: '3', name: 'Marriage'),
    CategoryModel(id: '4', name: 'Confidence'),
  ].obs;

  final RxList agents = [
    AgentModel(
      id: '1',
      displayName: 'Priya Sharma',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
      bio:
          'Expert relationship counselor helping you find clarity and emotional connection.',
      location: 'Mumbai, India',
      pricePerMinute: 5.0,
      languages: ['Hindi', 'English'],
      category: 'Relationship',
      topics: ['Breakup', 'Dating Advice', 'Emotional Support'],
      isOnline: true,
      isAudioAvailable: true,
      isVideoAvailable: true, // Both available
    ),
    AgentModel(
      id: '2',
      displayName: 'Ananya Verma',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      bio:
          'Specialized marriage and partner compatibility guide with years of insight.',
      location: 'Delhi, India',
      pricePerMinute: 7.0,
      languages: ['English', 'Punjabi', 'Urdu'],
      category: 'Marriage',
      topics: ['Kundali Match', 'Commitment', 'Family Issues'],
      isOnline: true,
      isAudioAvailable: true,
      isVideoAvailable: false, // Only Audio available
    ),
    AgentModel(
      id: '3',
      displayName: 'Rohan Malhotra',
      avatarUrl:
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
      bio:
          'Life coach focused on confidence building, personal growth, and positive thinking.',
      location: 'Bangalore, India',
      pricePerMinute: 5.0,
      languages: ['Hindi', 'English', 'Kannada'],
      category: 'Confidence',
      topics: ['Public Speaking', 'Mindset', 'Motivation'],
      isOnline: true,
      isAudioAvailable: false,
      isVideoAvailable: true, // Only Video available
    ),
    AgentModel(
      id: '4',
      displayName: 'Simran Kaur',
      avatarUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
      bio:
          'Celebrity advisor sharing exclusive lifestyle, media, and networking guidance.',
      location: 'Chandigarh, India',
      pricePerMinute: 10.0,
      languages: ['Hindi', 'English', 'Urdu'],
      category: 'Star',
      topics: ['Media', 'Networking', 'Exclusive Chat'],
      isOnline: true,
      isAudioAvailable: true,
      isVideoAvailable: true,
    ),
  ].obs;

  late final Rx selectedCategory;
  final RxString selectedLanguage = 'All'.obs;
  final RxString selectedCallType = 'All'.obs; // 👉 'All', 'Audio', 'Video'

  @override
  void onInit() {
    super.onInit();
    if (categories.isNotEmpty) {
      selectedCategory = Rx(categories.first);
      CategoryModel.current = categories.first;
    } else {
      final defaultCat = CategoryModel(id: '0', name: 'All');
      selectedCategory = Rx(defaultCat);
      CategoryModel.current = defaultCat;
    }
  }

  void setPriorityCategory(CategoryModel category) {
    selectedCategory.value = category;
    CategoryModel.current = category;
    update();
  }

  void setLanguageFilter(String lang) {
    selectedLanguage.value = lang;
    update();
  }

  // 👉 Call Type Filter Handler
  void setCallTypeFilter(String callType) {
    selectedCallType.value = callType;
    update();
  }

  void setPriorityAgent(AgentModel agent) {
    AgentModel.current = agent;
    update();
  }

  List get filteredAgents {
    final activeCategoryName = selectedCategory.value.name;
    var list = agents.toList();

    // Category Filter
    if (activeCategoryName != 'All') {
      list = list
          .where(
            (agent) =>
                agent.category.toLowerCase() ==
                activeCategoryName.toLowerCase(),
          )
          .toList();
    }

    // Language Filter
    if (selectedLanguage.value != 'All') {
      list = list
          .where(
            (agent) => agent.languages.any(
              (lang) =>
                  lang.toLowerCase() == selectedLanguage.value.toLowerCase(),
            ),
          )
          .toList();
    }

    // 👉 Call Type Filter Logic
    if (selectedCallType.value != 'All') {
      if (selectedCallType.value.toLowerCase() == 'audio') {
        list = list.where((agent) => agent.isAudioAvailable).toList();
      } else if (selectedCallType.value.toLowerCase() == 'video') {
        list = list.where((agent) => agent.isVideoAvailable).toList();
      }
    }

    // Priority Sorting: Online agents first
    list.sort((a, b) => (b.isOnline ? 1 : 0).compareTo(a.isOnline ? 1 : 0));

    return list;
  }
}
