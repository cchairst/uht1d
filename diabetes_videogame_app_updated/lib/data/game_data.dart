// Food data for Carb Counter game
class FoodItem {
  final String name;
  final int carbs;
  final String emoji;
  final String hint;

  const FoodItem({
    required this.name,
    required this.carbs,
    required this.emoji,
    required this.hint,
  });
}

const List<FoodItem> foodItems = [
  FoodItem(name: 'Apple', carbs: 25, emoji: '🍎', hint: 'Medium fruit'),
  FoodItem(name: 'Banana', carbs: 27, emoji: '🍌', hint: 'Yellow fruit'),
  FoodItem(name: 'Slice of Bread', carbs: 15, emoji: '🍞', hint: 'Grain product'),
  FoodItem(name: 'Rice Bowl', carbs: 45, emoji: '🍚', hint: 'Starchy grain'),
  FoodItem(name: 'Pasta Plate', carbs: 43, emoji: '🍝', hint: 'Italian classic'),
  FoodItem(name: 'Orange Juice (8oz)', carbs: 26, emoji: '🧃', hint: 'Fruit drink'),
  FoodItem(name: 'Chocolate Bar', carbs: 35, emoji: '🍫', hint: 'Sweet treat'),
  FoodItem(name: 'Egg', carbs: 1, emoji: '🥚', hint: 'Protein source'),
  FoodItem(name: 'Chicken Breast', carbs: 0, emoji: '🍗', hint: 'Lean meat'),
  FoodItem(name: 'Potato', carbs: 37, emoji: '🥔', hint: 'Root vegetable'),
  FoodItem(name: 'Milk (8oz)', carbs: 12, emoji: '🥛', hint: 'Dairy drink'),
  FoodItem(name: 'Yogurt Cup', carbs: 17, emoji: '🥛', hint: 'Fermented dairy'),
  FoodItem(name: 'Pizza Slice', carbs: 36, emoji: '🍕', hint: 'Fast food favorite'),
  FoodItem(name: 'Ice Cream Scoop', carbs: 16, emoji: '🍨', hint: 'Frozen dessert'),
  FoodItem(name: 'Hamburger', carbs: 40, emoji: '🍔', hint: 'Includes bun'),
  FoodItem(name: 'Salad (no dressing)', carbs: 5, emoji: '🥗', hint: 'Leafy greens'),
  FoodItem(name: 'Soda Can', carbs: 39, emoji: '🥤', hint: 'Fizzy drink'),
  FoodItem(name: 'Diet Soda', carbs: 0, emoji: '🥤', hint: 'Zero sugar'),
  FoodItem(name: 'Cookie', carbs: 20, emoji: '🍪', hint: 'Baked sweet'),
  FoodItem(name: 'Donut', carbs: 25, emoji: '🍩', hint: 'Ring-shaped pastry'),
];

// Emergency scenario data
class EmergencyOption {
  final String text;
  final bool correct;
  final String feedback;

  const EmergencyOption({
    required this.text,
    required this.correct,
    required this.feedback,
  });
}

class EmergencyScenario {
  final String situation;
  final List<EmergencyOption> options;
  final String category;

  const EmergencyScenario({
    required this.situation,
    required this.options,
    required this.category,
  });
}

const List<EmergencyScenario> emergencyScenarios = [
  EmergencyScenario(
    situation: "Your friend with diabetes is confused, sweating, and shaking. Their blood glucose is 45 mg/dL.",
    category: "Hypoglycemia",
    options: [
      EmergencyOption(
        text: "Give them insulin immediately",
        correct: false,
        feedback: "No! They're having low blood sugar. Insulin would make it worse.",
      ),
      EmergencyOption(
        text: "Give them orange juice or glucose tablets",
        correct: true,
        feedback: "Correct! Fast-acting sugar helps raise blood glucose quickly.",
      ),
      EmergencyOption(
        text: "Tell them to exercise",
        correct: false,
        feedback: "Exercise would lower blood sugar further - dangerous in this situation.",
      ),
      EmergencyOption(
        text: "Wait and see if it gets better",
        correct: false,
        feedback: "Severe hypoglycemia is an emergency. Action is needed now!",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "Blood glucose reading shows 320 mg/dL and you're feeling nauseous with fruity breath odor.",
    category: "Hyperglycemia/DKA",
    options: [
      EmergencyOption(
        text: "Eat a meal to feel better",
        correct: false,
        feedback: "Eating would raise blood sugar even higher.",
      ),
      EmergencyOption(
        text: "Take rapid-acting insulin and drink water, check for ketones",
        correct: true,
        feedback: "Correct! High glucose with nausea and fruity breath may indicate DKA risk.",
      ),
      EmergencyOption(
        text: "Go to sleep and check in the morning",
        correct: false,
        feedback: "This could be diabetic ketoacidosis - a medical emergency!",
      ),
      EmergencyOption(
        text: "Drink sugary juice",
        correct: false,
        feedback: "This would dangerously raise blood sugar further.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "You're about to exercise and your blood glucose is 85 mg/dL.",
    category: "Exercise Safety",
    options: [
      EmergencyOption(
        text: "Exercise immediately - that's a perfect level",
        correct: false,
        feedback: "85 is borderline low for exercise; blood sugar will drop during activity.",
      ),
      EmergencyOption(
        text: "Have a small carb snack (15-20g) before exercising",
        correct: true,
        feedback: "Correct! A snack prevents hypoglycemia during exercise.",
      ),
      EmergencyOption(
        text: "Take extra insulin before exercise",
        correct: false,
        feedback: "This would cause dangerous low blood sugar during exercise.",
      ),
      EmergencyOption(
        text: "Skip exercise today",
        correct: false,
        feedback: "You can still exercise safely with proper preparation.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "Your insulin pump has stopped working and you don't have a backup. Blood glucose is 200 mg/dL and rising.",
    category: "Equipment Failure",
    options: [
      EmergencyOption(
        text: "Wait for the pump to start working again",
        correct: false,
        feedback: "Without insulin, blood sugar will continue rising dangerously.",
      ),
      EmergencyOption(
        text: "Take a correction dose with an insulin pen/syringe and call your doctor",
        correct: true,
        feedback: "Correct! You need an alternative insulin delivery method immediately.",
      ),
      EmergencyOption(
        text: "Exercise vigorously to bring it down",
        correct: false,
        feedback: "Without insulin, exercise alone won't adequately control rising glucose.",
      ),
      EmergencyOption(
        text: "Drink lots of water and skip your next meal",
        correct: false,
        feedback: "You still need insulin - water alone won't solve this.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "You wake up at 3 AM feeling sweaty with a blood glucose of 55 mg/dL.",
    category: "Night-time Hypoglycemia",
    options: [
      EmergencyOption(
        text: "Go back to sleep, it will correct itself",
        correct: false,
        feedback: "Nocturnal hypoglycemia is dangerous and needs treatment.",
      ),
      EmergencyOption(
        text: "Take 15-20g fast-acting carbs, recheck in 15 minutes",
        correct: true,
        feedback: "Correct! Follow the 15-15 rule: 15g carbs, wait 15 minutes, recheck.",
      ),
      EmergencyOption(
        text: "Take your morning insulin dose early",
        correct: false,
        feedback: "More insulin would make low blood sugar worse!",
      ),
      EmergencyOption(
        text: "Call 911 immediately",
        correct: false,
        feedback: "55 mg/dL is treatable at home if you're conscious and can swallow.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "You're feeling fine but your CGM shows blood glucose dropping rapidly from 140 to 90 in 20 minutes.",
    category: "Trend Monitoring",
    options: [
      EmergencyOption(
        text: "Ignore it - 90 is still normal",
        correct: false,
        feedback: "The rapid drop suggests it will continue falling - be proactive!",
      ),
      EmergencyOption(
        text: "Take insulin to stabilize it",
        correct: false,
        feedback: "Insulin would accelerate the drop.",
      ),
      EmergencyOption(
        text: "Have a small snack and monitor closely",
        correct: true,
        feedback: "Correct! Rapid drops often continue. A snack prevents hypoglycemia.",
      ),
      EmergencyOption(
        text: "Exercise to burn off excess insulin",
        correct: false,
        feedback: "Exercise would make blood sugar drop even faster.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "Your child with diabetes is sick with the flu, not eating much, and blood glucose is 180 mg/dL.",
    category: "Sick Day Management",
    options: [
      EmergencyOption(
        text: "Skip insulin since they're not eating",
        correct: false,
        feedback: "Never skip basal insulin! Illness often raises blood sugar.",
      ),
      EmergencyOption(
        text: "Give usual basal insulin, adjust meal doses, monitor for ketones",
        correct: true,
        feedback: "Correct! Sick day management requires careful monitoring and hydration.",
      ),
      EmergencyOption(
        text: "Double the insulin to fight the illness",
        correct: false,
        feedback: "Too much insulin with reduced eating causes hypoglycemia.",
      ),
      EmergencyOption(
        text: "Let them eat whatever they want to get energy",
        correct: false,
        feedback: "Blood sugar management is still important during illness.",
      ),
    ],
  ),
  EmergencyScenario(
    situation: "After eating a large meal, blood glucose spikes to 280 mg/dL. It's been 30 minutes since you took insulin.",
    category: "Post-meal Spikes",
    options: [
      EmergencyOption(
        text: "Take another full dose of rapid insulin",
        correct: false,
        feedback: "Stacking insulin causes dangerous lows later. Wait for the first dose to work.",
      ),
      EmergencyOption(
        text: "Go for a light walk and wait for insulin to peak",
        correct: true,
        feedback: "Correct! Light activity helps, and rapid insulin peaks around 1-2 hours.",
      ),
      EmergencyOption(
        text: "Eat more protein to balance it out",
        correct: false,
        feedback: "More food won't lower blood sugar.",
      ),
      EmergencyOption(
        text: "Panic and go to the emergency room",
        correct: false,
        feedback: "280 mg/dL after a meal, with insulin on board, isn't an emergency yet.",
      ),
    ],
  ),
];

// Insulin timing data
class InsulinOption {
  final String text;
  final String timing;
  final String feedback;

  const InsulinOption({
    required this.text,
    required this.timing,
    required this.feedback,
  });
}

class InsulinScenario {
  final String question;
  final List<InsulinOption> options;
  final String insulinType;
  final String correctTiming;
  final String? mealType;

  const InsulinScenario({
    required this.question,
    required this.options,
    required this.insulinType,
    required this.correctTiming,
    this.mealType,
  });
}

const List<InsulinScenario> insulinScenarios = [
  InsulinScenario(
    question: "When should you take rapid-acting insulin relative to a meal?",
    insulinType: "rapid",
    correctTiming: "optimal",
    options: [
      InsulinOption(
        text: "30-45 minutes before eating",
        timing: "early",
        feedback: "This timing works for regular insulin, but rapid-acting works faster.",
      ),
      InsulinOption(
        text: "15-20 minutes before eating",
        timing: "optimal",
        feedback: "Correct! This allows rapid insulin to start working as food is absorbed.",
      ),
      InsulinOption(
        text: "Right as you start eating",
        timing: "late",
        feedback: "This can cause a post-meal spike before insulin catches up.",
      ),
      InsulinOption(
        text: "30 minutes after eating",
        timing: "very_late",
        feedback: "Too late! Blood sugar will spike significantly before insulin works.",
      ),
    ],
  ),
  InsulinScenario(
    question: "You're about to eat a high-fat meal like pizza. When should you take rapid insulin?",
    insulinType: "rapid",
    correctTiming: "optimal",
    mealType: "high-fat",
    options: [
      InsulinOption(
        text: "All at once, 15 minutes before eating",
        timing: "standard",
        feedback: "Fat slows digestion - you may go low then high later.",
      ),
      InsulinOption(
        text: "Split dose: some before, some 1-2 hours after",
        timing: "optimal",
        feedback: "Correct! Fat delays carb absorption, so extended coverage helps.",
      ),
      InsulinOption(
        text: "Double dose right before eating",
        timing: "wrong",
        feedback: "This causes early hypoglycemia and doesn't address delayed absorption.",
      ),
      InsulinOption(
        text: "Skip the pre-meal dose, take it all after",
        timing: "late",
        feedback: "You'll spike significantly before the late insulin works.",
      ),
    ],
  ),
  InsulinScenario(
    question: "When is the best time to take long-acting (basal) insulin?",
    insulinType: "basal",
    correctTiming: "optimal",
    options: [
      InsulinOption(
        text: "Only when blood sugar is high",
        timing: "reactive",
        feedback: "Basal insulin should be taken consistently, not reactively.",
      ),
      InsulinOption(
        text: "At the same time every day",
        timing: "optimal",
        feedback: "Correct! Consistency helps maintain steady background insulin levels.",
      ),
      InsulinOption(
        text: "Right before each meal",
        timing: "wrong",
        feedback: "That's when rapid insulin is used. Basal is usually once or twice daily.",
      ),
      InsulinOption(
        text: "Whenever you remember",
        timing: "inconsistent",
        feedback: "Inconsistent timing leads to gaps or overlaps in coverage.",
      ),
    ],
  ),
  InsulinScenario(
    question: "Your blood sugar is 250 mg/dL before lunch. When should you take your correction + meal dose?",
    insulinType: "rapid",
    correctTiming: "optimal",
    options: [
      InsulinOption(
        text: "Wait until blood sugar normalizes, then eat",
        timing: "delayed",
        feedback: "This can work but delays your meal significantly.",
      ),
      InsulinOption(
        text: "Take correction now, eat in 20-30 minutes",
        timing: "optimal",
        feedback: "Correct! Giving insulin a head start helps with high starting glucose.",
      ),
      InsulinOption(
        text: "Eat first, then take insulin based on how you feel",
        timing: "reactive",
        feedback: "This leads to even higher post-meal spikes.",
      ),
      InsulinOption(
        text: "Skip the correction, just take meal insulin",
        timing: "insufficient",
        feedback: "You need extra insulin to address the already-high glucose.",
      ),
    ],
  ),
  InsulinScenario(
    question: "You're having a low-carb meal (grilled chicken salad). How should you adjust rapid insulin timing?",
    insulinType: "rapid",
    correctTiming: "optimal",
    mealType: "low-carb",
    options: [
      InsulinOption(
        text: "Take same amount 15-20 minutes before",
        timing: "standard",
        feedback: "Less carbs means less insulin needed, not just same timing.",
      ),
      InsulinOption(
        text: "Reduce dose and take closer to meal time",
        timing: "optimal",
        feedback: "Correct! Fewer carbs need less insulin, and protein/fat digest slower.",
      ),
      InsulinOption(
        text: "Skip rapid insulin entirely",
        timing: "skip",
        feedback: "Even low-carb meals may need some coverage for protein effects.",
      ),
      InsulinOption(
        text: "Take insulin 45 minutes before",
        timing: "early",
        feedback: "With fewer carbs, this timing risks hypoglycemia.",
      ),
    ],
  ),
];
