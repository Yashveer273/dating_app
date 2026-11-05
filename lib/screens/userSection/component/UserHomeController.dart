// ==========================================
// UserHomeController.dart (Complete Final Code)
// ==========================================
import 'package:get/get.dart';
import 'package:talk24loves/Api/UserApiService.dart';
import 'package:talk24loves/screens/caling_agent_dashboard/component/agent_storage.dart';
import 'package:talk24loves/screens/userSection/model/AgentListModel.dart';

class UserHomeController extends GetxController {
  final RxList<CategoryModel> categories = <CategoryModel>[
    CategoryModel(id: '0', name: 'All'),
  ].obs;

  final RxList<AgentModel> agents = <AgentModel>[].obs;
  final RxList<AgentModel> savedAgentsList = <AgentModel>[].obs;

  late final Rx selectedCategory;
  final RxString selectedLanguage = 'All'.obs;
  final RxString selectedCallType = 'All'.obs;

  final RxString savedSelectedLanguage = 'All'.obs;
  final RxString savedSelectedCallType = 'All'.obs;

  final UserApiService _apiService = Get.put(UserApiService());
  final RxBool isLoading = false.obs;
  final RxBool isLoadingSaved = false.obs;

  final RxSet<String> savedAgentIdsSet = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    final defaultCat = CategoryModel(id: '0', name: 'All');
    selectedCategory = Rx(defaultCat);
    CategoryModel.current = defaultCat;

    loadSavedAgentIdsFromStorage();
    loadHomeDataFromApi();
    fetchSavedAgentsFromApi();
  }

  void loadSavedAgentIdsFromStorage() {
    final storedIds = AgentStorage.getSavedAgentIds();
    savedAgentIdsSet.assignAll(storedIds);
    update();
  }

  bool isAgentSaved(String agentId) {
    return savedAgentIdsSet.contains(agentId);
  }

  // 👉 Fixed toggleSaveAgent: Instantly updates state & removes card from saved list on un-save
  Future<void> toggleSaveAgent(String agentId) async {
    print("Toggling save for agentId: $agentId");
    if (agentId.isEmpty) return;

    // 1. Local storage mein save/remove karein (FIFO 30 limit)
    await AgentStorage.toggleSaveAgentId(agentId);

    // 2. Local reactive set ko refresh karein
    loadSavedAgentIdsFromStorage();

    // 3. Check karein ki ab agent saved hai ya un-saved ho gaya hai
    final bool currentlySaved = isAgentSaved(agentId);

    // 4. Sabhi lists mein agent ka `isSaved` status sync karein taaki buttons theek dikhein
    for (var a in agents) {
      final id = a.agentId.isNotEmpty ? a.agentId : a.id;
      if (id == agentId) {
        a.isSaved.value = currentlySaved;
      }
    }
    for (var a in savedAgentsList) {
      final id = a.agentId.isNotEmpty ? a.agentId : a.id;
      if (id == agentId) {
        a.isSaved.value = currentlySaved;
      }
    }

    // 5. Agar un-save kiya hai, toh turant `savedAgentsList` se hata dein taaki card screen se gayab ho jaye
    if (!currentlySaved) {
      savedAgentsList.removeWhere((a) {
        final id = a.agentId.isNotEmpty ? a.agentId : a.id;
        return id == agentId;
      });
    }

    // 6. UI ko instantly refresh karein
    update();
  }

  // Fetch Saved Agents from API passing up to 30 IDs
  Future<void> fetchSavedAgentsFromApi() async {
    try {
      final storedIds = AgentStorage.getSavedAgentIds();
      print("Fetching saved agents from API...$storedIds");
      if (storedIds.isEmpty) {
        savedAgentsList.clear();
        return;
      }

      isLoadingSaved.value = true;

      final responseData = await _apiService.fetchMySavedAgents(storedIds);

      if (responseData != null && responseData['status'] == true) {
        var rawData = responseData['data'];
        List<AgentModel> parsedAgents = [];

        if (rawData != null && rawData['agents'] is List) {
          List agentsJson = rawData['agents'];
          parsedAgents = agentsJson
              .map(
                (json) => AgentModel.fromJson(
                  Map<String, dynamic>.from(json),
                  isSaved: true,
                ),
              )
              .toList();
        }

        savedAgentsList.assignAll(parsedAgents);
        print("Successfully parsed ${parsedAgents.length} saved agents.");
      } else {
        savedAgentsList.clear();
      }
    } catch (e) {
      print("Error fetching saved agents from API: $e");
      savedAgentsList.clear();
    } finally {
      isLoadingSaved.value = false;
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

  void setCallTypeFilter(String callType) {
    selectedCallType.value = callType;
    update();
  }

  void setSavedLanguageFilter(String lang) {
    savedSelectedLanguage.value = lang;
    update();
  }

  void setSavedCallTypeFilter(String callType) {
    savedSelectedCallType.value = callType;
    update();
  }

  void setPriorityAgent(AgentModel agent) {
    AgentModel.current = agent;
    update();
  }

  // 👉 Filtered Saved Agents Getter with Comma-Separated Category Support
  List<AgentModel> get filteredSavedAgents {
    final activeCategoryName = selectedCategory.value.name.trim();
    var list = savedAgentsList.toList();

    // 1. Category Filter (Handling comma-separated string like "General, Love")
    if (activeCategoryName.toLowerCase() != 'all') {
      list = list.where((agent) {
        final agentCatStr = agent.category.toLowerCase();
        final selectedCatLower = activeCategoryName.toLowerCase();

        List<String> categoriesList = agentCatStr
            .split(',')
            .map((e) => e.trim())
            .toList();

        return categoriesList.contains(selectedCatLower) ||
            agentCatStr.contains(selectedCatLower);
      }).toList();
    }

    // 2. Language Filter
    if (savedSelectedLanguage.value.toLowerCase() != 'all') {
      list = list
          .where(
            (agent) => agent.languages.any(
              (lang) =>
                  lang.toLowerCase() ==
                  savedSelectedLanguage.value.toLowerCase(),
            ),
          )
          .toList();
    }

    // 3. Call Type Filter
    if (savedSelectedCallType.value.toLowerCase() != 'all') {
      if (savedSelectedCallType.value.toLowerCase() == 'audio') {
        list = list.where((agent) => agent.isAudioAvailable).toList();
      } else if (savedSelectedCallType.value.toLowerCase() == 'video') {
        list = list.where((agent) => agent.isVideoAvailable).toList();
      }
    }

    list.sort((a, b) => (b.isOnline ? 1 : 0).compareTo(a.isOnline ? 1 : 0));
    return list;
  }

  List<AgentModel> get filteredAgents {
    final activeCategoryName = selectedCategory.value.name.trim();
    var list = agents.toList();

    if (activeCategoryName.toLowerCase() != 'all') {
      list = list.where((agent) {
        final agentCatStr = agent.category.toLowerCase();
        final selectedCatLower = activeCategoryName.toLowerCase();

        List<String> categoriesList = agentCatStr
            .split(',')
            .map((e) => e.trim())
            .toList();

        return categoriesList.contains(selectedCatLower) ||
            agentCatStr.contains(selectedCatLower);
      }).toList();
    }

    if (selectedLanguage.value.toLowerCase() != 'all') {
      list = list
          .where(
            (agent) => agent.languages.any(
              (lang) =>
                  lang.toLowerCase() == selectedLanguage.value.toLowerCase(),
            ),
          )
          .toList();
    }

    if (selectedCallType.value.toLowerCase() != 'all') {
      if (selectedCallType.value.toLowerCase() == 'audio') {
        list = list.where((agent) => agent.isAudioAvailable).toList();
      } else if (selectedCallType.value.toLowerCase() == 'video') {
        list = list.where((agent) => agent.isVideoAvailable).toList();
      }
    }

    list.sort((a, b) => (b.isOnline ? 1 : 0).compareTo(a.isOnline ? 1 : 0));

    return list;
  }

  Future searchAgentsById(String id) async {
    if (id.trim().isEmpty) {
      loadHomeDataFromApi();
      return;
    }

    try {
      if (isLoading.value) return;
      isLoading.value = true;

      final response = await _apiService.fetchagentbyid(id);

      if (response != null && response['status'] == true) {
        var rawData = response['data'];
        List<AgentModel> parsedAgents = [];

        if (rawData != null) {
          if (rawData is List) {
            parsedAgents = rawData
                .map(
                  (json) =>
                      AgentModel.fromJson(Map<String, dynamic>.from(json)),
                )
                .toList();
          } else if (rawData is Map) {
            parsedAgents = [
              AgentModel.fromJson(Map<String, dynamic>.from(rawData)),
            ];
          }
        }

        agents.assignAll(parsedAgents);
      } else {
        agents.clear();
      }
    } catch (e) {
      print("Error searching agent by ID: $e");
      agents.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future loadHomeDataFromApi() async {
    try {
      if (isLoading.value) return;
      isLoading.value = true;
      final responseData = await _apiService.fetchHomeData();

      if (responseData != null) {
        List rawCategories = responseData['categories'] ?? [];
        List<CategoryModel> parsedCategories = rawCategories
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        if (parsedCategories.isNotEmpty) {
          parsedCategories.sort((a, b) {
            if (a.name.toLowerCase() == 'all') return -1;
            if (b.name.toLowerCase() == 'all') return 1;
            return 0;
          });

          categories.assignAll(parsedCategories);
          selectedCategory.value = categories.first;
          CategoryModel.current = categories.first;
        } else {
          final defaultCat = CategoryModel(id: '0', name: 'All');
          categories.assignAll([defaultCat]);
          selectedCategory.value = defaultCat;
          CategoryModel.current = defaultCat;
        }

        List rawAgents = responseData['agents'] ?? [];
        List<AgentModel> parsedAgents = rawAgents
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

  get _userEndpoint => '';
}
