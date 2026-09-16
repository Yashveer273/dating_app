// ==========================================
// UserHomeController.dart (Updated with Call Type Filter)
// ==========================================
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/screens/userSection/model/AgentModel.dart';

class UserHomeController extends GetxController {
  final RxList categories = [CategoryModel(id: '0', name: 'All')].obs;

  final RxList agents = [].obs;

  late final Rx selectedCategory;
  final RxString selectedLanguage = 'All'.obs;
  final RxString selectedCallType = 'All'.obs; // 👉 'All', 'Audio', 'Video'
  final UserApiService _apiService = Get.put(UserApiService());
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final defaultCat = CategoryModel(id: '0', name: 'All');
    selectedCategory = Rx(defaultCat);
    CategoryModel.current = defaultCat;
    loadHomeDataFromApi();
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

  Future loadHomeDataFromApi() async {
    try {
      if (isLoading.value) {
        return;
      }
      isLoading.value = true;
      final responseData = await _apiService.fetchHomeData();

      if (responseData != null) {
        // --- Categories Parsing & Model Insertion ---
        List rawCategories = responseData['categories'] ?? [];
        List parsedCategories = rawCategories
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        if (parsedCategories.isNotEmpty) {
          // 👉 Yeh logic ensure karega ki "All" (case-insensitive) chahe jahan bhi ho,
          // API response aate hi sabse pehle (first stage) par aa jaye.
          parsedCategories.sort((a, b) {
            if (a.name.toLowerCase() == 'all') return -1;
            if (b.name.toLowerCase() == 'all') return 1;
            return 0; // Baaki categories ka order same rahega
          });

          categories.assignAll(parsedCategories);

          // Pehli category ('All' ya jo bhi top par aayi) ko default select kar lo
          selectedCategory.value = categories.first;
          CategoryModel.current = categories.first;
        } else {
          // Fallback agar API se categories khali aayin
          final defaultCat = CategoryModel(id: '0', name: 'All');
          categories.assignAll([defaultCat]);
          selectedCategory.value = defaultCat;
          CategoryModel.current = defaultCat;
        }

        // --- Agents Parsing & Model Insertion ---
        List rawAgents = responseData['agents'] ?? [];
        List parsedAgents = rawAgents
            .map((json) => AgentModel.fromJson(json))
            .toList();

        agents.assignAll(parsedAgents);
      }
    } catch (e) {
      print("Error loading home data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
